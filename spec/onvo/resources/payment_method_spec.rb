# frozen_string_literal: true

RSpec.describe Onvo::PaymentMethod do
  describe ".retrieve" do
    it "GETs /payment-methods/:id" do
      stub_onvo(:get, "/payment-methods/pm_test_abc123", response_body: payment_method_response)
      result = described_class.retrieve("pm_test_abc123")
      expect(result.id).to eq("pm_test_abc123")
    end

    it "provides access to nested card object" do
      stub_onvo(:get, "/payment-methods/pm_test_abc123", response_body: payment_method_response)
      result = described_class.retrieve("pm_test_abc123")
      expect(result.card.last4).to eq("4242")
      expect(result.card.brand).to eq("visa")
    end
  end

  describe ".list" do
    it "GETs /payment-methods and returns a ListObject" do
      stub_onvo(:get, "/payment-methods",
                response_body: list_response(data: [payment_method_response]),)
      result = described_class.list
      expect(result).to be_a(Onvo::ListObject)
    end

    it "passes customer_id as query param" do
      stub = stub_request(:get, "#{OnvoHelpers::TEST_API_BASE}/payment-methods")
             .with(query: hash_including("customerId" => "cus_test_abc123"))
             .to_return(body: list_response(data: []).to_json, headers: { "Content-Type" => "application/json" })

      described_class.list(customer_id: "cus_test_abc123")
      expect(stub).to have_been_requested
    end
  end

  describe ".attach" do
    it "POSTs to /payment-methods/:id/attach" do
      stub_onvo(:post, "/payment-methods/pm_test_abc123/attach",
                response_body: payment_method_response("customer_id" => "cus_123"),)
      result = described_class.attach("pm_test_abc123", customer_id: "cus_123")
      expect(WebMock).to have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/payment-methods/pm_test_abc123/attach")
        .with(body: hash_including("customerId" => "cus_123"))
      expect(result.customer_id).to eq("cus_123")
    end
  end

  describe ".detach" do
    it "POSTs to /payment-methods/:id/detach" do
      stub = stub_onvo(:post, "/payment-methods/pm_test_abc123/detach",
                       response_body: payment_method_response("customer_id" => nil),)
      described_class.detach("pm_test_abc123")
      expect(stub).to have_been_requested
    end
  end
end
