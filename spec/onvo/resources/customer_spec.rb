# frozen_string_literal: true

RSpec.describe Onvo::Customer do
  describe ".create" do
    it "POSTs to /customers and returns an OnvoObject" do
      stub_onvo(:post, "/customers", response_body: customer_response)
      result = described_class.create(name: "Ana", email: "ana@example.com")
      expect(result).to be_a(Onvo::OnvoObject)
      expect(result.id).to eq("cus_test_abc123")
    end

    it "converts snake_case params to camelCase" do
      stub_onvo(:post, "/customers", response_body: customer_response)
      described_class.create(phone_number: "555-1234")
      expect(WebMock).to have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/customers")
        .with(body: hash_including("phoneNumber" => "555-1234"))
    end
  end

  describe ".retrieve" do
    it "GETs /customers/:id and returns the customer" do
      stub_onvo(:get, "/customers/cus_test_abc123", response_body: customer_response)
      result = described_class.retrieve("cus_test_abc123")
      expect(result.email).to eq("test@example.com")
    end

    it "raises InvalidRequestError when id is empty" do
      expect { described_class.retrieve("") }.to raise_error(Onvo::InvalidRequestError)
    end
  end

  describe ".update" do
    it "POSTs to /customers/:id and returns the updated customer" do
      updated = customer_response("name" => "Ana M.")
      stub_onvo(:post, "/customers/cus_test_abc123", response_body: updated)
      result = described_class.update("cus_test_abc123", name: "Ana M.")
      expect(result.name).to eq("Ana M.")
    end
  end

  describe ".delete" do
    it "DELETEs /customers/:id and returns a deleted response" do
      stub_onvo(:delete, "/customers/cus_test_abc123", response_body: deleted_response("cus_test_abc123"))
      result = described_class.delete("cus_test_abc123")
      expect(result.deleted).to be(true)
    end
  end

  describe ".list" do
    it "GETs /customers and returns a ListObject" do
      stub_onvo(:get, "/customers",
                response_body: list_response(data: [customer_response, customer_response("id" => "cus_2")]),)
      result = described_class.list
      expect(result).to be_a(Onvo::ListObject)
      expect(result.data.length).to eq(2)
    end

    it "passes filter params as query string" do
      stub = stub_request(:get, "#{OnvoHelpers::TEST_API_BASE}/customers")
             .with(query: hash_including("limit" => "5"))
             .to_return(body: list_response(data: []).to_json, headers: { "Content-Type" => "application/json" })

      described_class.list(limit: 5)
      expect(stub).to have_been_requested
    end
  end
end
