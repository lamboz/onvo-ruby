# frozen_string_literal: true

RSpec.describe Onvo::Client do
  subject(:client) do
    Onvo::Client.new(Onvo.configuration.tap { |c| c.secret_key = OnvoHelpers::TEST_SECRET_KEY })
  end

  let(:api_base) { OnvoHelpers::TEST_API_BASE }

  describe "request building" do
    it "sends the Authorization header" do
      stub_onvo(:get, "/customers", response_body: list_response(data: []))
      client.get("/customers")
      expect(WebMock).to have_requested(:get, "#{api_base}/customers")
        .with(headers: { "Authorization" => "Bearer #{OnvoHelpers::TEST_SECRET_KEY}" })
    end

    it "sends the Content-Type header" do
      stub_onvo(:post, "/customers", response_body: customer_response)
      client.post("/customers", { name: "Test" })
      expect(WebMock).to have_requested(:post, "#{api_base}/customers")
        .with(headers: { "Content-Type" => "application/json" })
    end

    it "sends a User-Agent header containing the gem version" do
      stub_onvo(:get, "/customers", response_body: list_response(data: []))
      client.get("/customers")
      expect(WebMock).to have_requested(:get, "#{api_base}/customers")
        .with(headers: { "User-Agent" => %r{onvo-ruby/#{Regexp.escape(Onvo::VERSION)}} })
    end

    it "converts snake_case body keys to camelCase" do
      stub_onvo(:post, "/customers", response_body: customer_response)
      client.post("/customers", { customer_id: "cus_123", phone_number: "555" })
      expect(WebMock).to have_requested(:post, "#{api_base}/customers")
        .with(body: hash_including("customerId" => "cus_123", "phoneNumber" => "555"))
    end

    it "appends query params to GET requests" do
      stub = stub_request(:get, "#{api_base}/customers")
             .with(query: hash_including("limit" => "10"))
             .to_return(body: list_response(data: []).to_json, headers: { "Content-Type" => "application/json" })

      client.get("/customers", { limit: 10 })
      expect(stub).to have_been_requested
    end
  end

  describe "response parsing" do
    it "returns an OnvoObject for single-resource responses" do
      stub_onvo(:get, "/customers/cus_123", response_body: customer_response)
      result = client.get("/customers/cus_123")
      expect(result).to be_a(Onvo::OnvoObject)
    end

    it "returns a ListObject for list responses" do
      stub_onvo(:get, "/customers", response_body: list_response(data: [customer_response]))
      result = client.get("/customers")
      expect(result).to be_a(Onvo::ListObject)
    end

    it "converts camelCase response keys to snake_case" do
      stub_onvo(:get, "/customers/cus_123",
                response_body: { "id" => "cus_123", "customerEmail" => "test@example.com" },)
      result = client.get("/customers/cus_123")
      expect(result.customer_email).to eq("test@example.com")
    end

    it "returns nil for empty responses" do
      stub_request(:delete, "#{api_base}/customers/cus_123")
        .to_return(status: 204, body: "", headers: {})
      result = client.delete("/customers/cus_123")
      expect(result).to be_nil
    end
  end

  describe "error mapping" do
    it "raises AuthenticationError on 401" do
      stub_onvo(:get, "/customers", status: 401, response_body: { "message" => "Unauthorized" })
      expect { client.get("/customers") }.to raise_error(Onvo::AuthenticationError)
    end

    it "raises InvalidRequestError on 400" do
      stub_onvo(:post, "/customers", status: 400, response_body: { "message" => "Bad request" })
      expect { client.post("/customers", {}) }.to raise_error(Onvo::InvalidRequestError)
    end

    it "raises NotFoundError on 404" do
      stub_onvo(:get, "/customers/bad_id", status: 404, response_body: { "message" => "Not found" })
      expect { client.get("/customers/bad_id") }.to raise_error(Onvo::NotFoundError)
    end

    it "raises RateLimitError on 429" do
      Onvo.configuration.max_retries = 0
      stub_onvo(:get, "/customers", status: 429, response_body: { "message" => "Rate limited" })
      expect { client.get("/customers") }.to raise_error(Onvo::RateLimitError)
    end

    it "raises ServerError on 500" do
      Onvo.configuration.max_retries = 0
      stub_onvo(:get, "/customers", status: 500, response_body: { "message" => "Server error" })
      expect { client.get("/customers") }.to raise_error(Onvo::ServerError)
    end
  end

  describe "retry behaviour" do
    before { Onvo.configuration.max_retries = 2 }

    it "retries on 429 and succeeds on the final attempt" do
      stub_request(:get, "#{api_base}/customers")
        .to_return({ status: 429, body: '{"message":"rate limited"}',
                     headers: { "Content-Type" => "application/json" }, })
        .then
        .to_return({ status: 429, body: '{"message":"rate limited"}',
                     headers: { "Content-Type" => "application/json" }, })
        .then
        .to_return({ status: 200, body: list_response(data: []).to_json,
                     headers: { "Content-Type" => "application/json" }, })

      result = client.get("/customers")
      expect(result).to be_a(Onvo::ListObject)
    end

    it "raises after exhausting all retries on 500" do
      stub_request(:get, "#{api_base}/customers")
        .to_return(status: 500, body: '{"message":"err"}', headers: { "Content-Type" => "application/json" })

      expect { client.get("/customers") }.to raise_error(Onvo::ServerError)
    end

    it "does not retry 400 client errors" do
      stub_request(:post, "#{api_base}/customers")
        .to_return(status: 400, body: '{"message":"bad"}', headers: { "Content-Type" => "application/json" })

      expect { client.post("/customers", {}) }.to raise_error(Onvo::InvalidRequestError)
      # Only 1 request should have been made (no retries)
      expect(WebMock).to have_requested(:post, "#{api_base}/customers").once
    end

    it "retries on network connection errors" do
      stub_request(:get, "#{api_base}/customers")
        .to_raise(Errno::ECONNREFUSED)
        .then
        .to_return(
          status: 200,
          body: list_response(data: []).to_json,
          headers: { "Content-Type" => "application/json" },
        )

      expect { client.get("/customers") }.not_to raise_error
    end

    it "raises APIConnectionError after exhausting retries on network errors" do
      stub_request(:get, "#{api_base}/customers").to_raise(Errno::ECONNREFUSED)
      expect { client.get("/customers") }.to raise_error(Onvo::APIConnectionError)
    end
  end

  describe "ConfigurationError" do
    it "raises ConfigurationError when secret_key is missing" do
      config = Onvo::Configuration.new
      config.secret_key = nil
      expect { Onvo::Client.new(config) }.to raise_error(Onvo::ConfigurationError)
    end
  end
end
