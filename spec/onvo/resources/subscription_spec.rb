# frozen_string_literal: true

RSpec.describe Onvo::Subscription do
  describe ".create" do
    it "POSTs to /subscriptions" do
      stub_onvo(:post, "/subscriptions", response_body: subscription_response)
      result = described_class.create(
        customer_id: "cus_test_abc123",
        items: [{ price_id: "price_456", quantity: 1 }],
      )
      expect(result.id).to eq("sub_test_abc123")
    end

    it "converts nested item keys to camelCase" do
      stub_onvo(:post, "/subscriptions", response_body: subscription_response)
      described_class.create(customer_id: "cus_1", items: [{ price_id: "price_1", quantity: 1 }])
      expect(WebMock).to(have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/subscriptions")
        .with { |req| JSON.parse(req.body).dig("items", 0, "priceId") == "price_1" })
    end
  end

  describe ".retrieve" do
    it "GETs /subscriptions/:id" do
      stub_onvo(:get, "/subscriptions/sub_test_abc123", response_body: subscription_response)
      result = described_class.retrieve("sub_test_abc123")
      expect(result.status).to eq("active")
    end
  end

  describe ".update" do
    it "PATCHes /subscriptions/:id" do
      updated = subscription_response("metadata" => { "order" => "1" })
      stub_onvo(:patch, "/subscriptions/sub_test_abc123", response_body: updated)
      result = described_class.update("sub_test_abc123", metadata: { "order" => "1" })
      expect(result.metadata).to eq("order" => "1")
    end
  end

  describe ".cancel" do
    it "POSTs to /subscriptions/:id/cancel" do
      stub_onvo(:post, "/subscriptions/sub_test_abc123/cancel",
                response_body: subscription_response("status" => "canceled"),)
      result = described_class.cancel("sub_test_abc123", at_period_end: true)
      expect(WebMock).to have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/subscriptions/sub_test_abc123/cancel")
        .with(body: hash_including("atPeriodEnd" => true))
      expect(result.status).to eq("canceled")
    end
  end

  describe ".pause" do
    it "POSTs to /subscriptions/:id/pause" do
      stub = stub_onvo(:post, "/subscriptions/sub_test_abc123/pause",
                       response_body: subscription_response("status" => "paused"),)
      result = described_class.pause("sub_test_abc123")
      expect(stub).to have_been_requested
      expect(result.status).to eq("paused")
    end
  end

  describe ".resume" do
    it "POSTs to /subscriptions/:id/resume" do
      stub = stub_onvo(:post, "/subscriptions/sub_test_abc123/resume",
                       response_body: subscription_response("status" => "active"),)
      result = described_class.resume("sub_test_abc123")
      expect(stub).to have_been_requested
      expect(result.status).to eq("active")
    end
  end

  describe ".list" do
    it "GETs /subscriptions and returns a ListObject" do
      stub_onvo(:get, "/subscriptions",
                response_body: list_response(data: [subscription_response]),)
      result = described_class.list
      expect(result).to be_a(Onvo::ListObject)
    end
  end
end
