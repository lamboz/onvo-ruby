# frozen_string_literal: true

RSpec.describe Onvo::OnvoError do
  it "inherits from StandardError" do
    expect(described_class.superclass).to eq(StandardError)
  end

  it "stores http_status, http_body, json_body, code" do
    err = described_class.new("oops", http_status: 400, http_body: '{"error":"bad"}',
                                      json_body: { "error" => "bad" }, code: "invalid_param",)
    expect(err.http_status).to eq(400)
    expect(err.http_body).to eq('{"error":"bad"}')
    expect(err.json_body).to eq("error" => "bad")
    expect(err.code).to eq("invalid_param")
    expect(err.message).to eq("oops")
  end
end

RSpec.describe Onvo::APIError do
  describe ".from_response" do
    it "returns AuthenticationError for 401" do
      err = described_class.from_response(401, '{"message":"Unauthorized"}')
      expect(err).to be_a(Onvo::AuthenticationError)
      expect(err.message).to eq("Unauthorized")
      expect(err.http_status).to eq(401)
    end

    it "returns InvalidRequestError for 400" do
      err = described_class.from_response(400, '{"error":{"message":"bad param","code":"invalid"}}')
      expect(err).to be_a(Onvo::InvalidRequestError)
      expect(err.message).to eq("bad param")
      expect(err.code).to eq("invalid")
    end

    it "returns PermissionError for 403" do
      err = described_class.from_response(403, '{"message":"Forbidden"}')
      expect(err).to be_a(Onvo::PermissionError)
    end

    it "returns NotFoundError for 404" do
      err = described_class.from_response(404, '{"message":"Not found"}')
      expect(err).to be_a(Onvo::NotFoundError)
    end

    it "returns RateLimitError for 429" do
      err = described_class.from_response(429, '{"message":"Too many requests"}')
      expect(err).to be_a(Onvo::RateLimitError)
    end

    it "returns ServerError for 500" do
      err = described_class.from_response(500, '{"message":"Internal server error"}')
      expect(err).to be_a(Onvo::ServerError)
    end

    it "returns ServerError for 503" do
      err = described_class.from_response(503, "Service Unavailable")
      expect(err).to be_a(Onvo::ServerError)
    end

    it "returns APIError for unrecognized status codes" do
      err = described_class.from_response(422, '{"message":"Unprocessable"}')
      expect(err).to be_a(Onvo::APIError)
    end

    it "handles non-JSON response bodies gracefully" do
      err = described_class.from_response(500, "Internal Server Error")
      expect(err.message).to eq("Internal Server Error")
    end
  end
end

RSpec.describe Onvo::NotFoundError do
  it "is a subclass of InvalidRequestError" do
    expect(described_class.superclass).to eq(Onvo::InvalidRequestError)
  end

  it "can be rescued as InvalidRequestError" do
    expect { raise described_class }.to raise_error(Onvo::InvalidRequestError)
  end
end

RSpec.describe Onvo::SignatureVerificationError do
  it "inherits from OnvoError" do
    expect(described_class.superclass).to eq(Onvo::OnvoError)
  end
end
