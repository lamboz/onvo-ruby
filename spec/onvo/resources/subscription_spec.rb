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
    it "POSTs to /subscriptions/:id" do
      updated = subscription_response("metadata" => { "order" => "1" })
      stub_onvo(:post, "/subscriptions/sub_test_abc123", response_body: updated)
      result = described_class.update("sub_test_abc123", metadata: { "order" => "1" })
      expect(result.metadata).to eq("order" => "1")
    end

    it "schedules a cancel-at-period-end via the same endpoint" do
      updated = subscription_response("cancel_at_period_end" => true)
      stub_onvo(:post, "/subscriptions/sub_test_abc123", response_body: updated)
      result = described_class.update("sub_test_abc123", cancel_at_period_end: true)
      expect(result.cancel_at_period_end).to be true
    end
  end

  describe ".confirm" do
    it "POSTs to /subscriptions/:id/confirm" do
      stub_onvo(:post, "/subscriptions/sub_test_abc123/confirm",
                response_body: subscription_response("status" => "active"),)
      result = described_class.confirm("sub_test_abc123", payment_method_id: "pm_123")
      expect(WebMock).to have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/subscriptions/sub_test_abc123/confirm")
        .with(body: hash_including("paymentMethodId" => "pm_123"))
      expect(result.status).to eq("active")
    end
  end

  describe ".cancel" do
    it "DELETEs /subscriptions/:id" do
      stub_onvo(:delete, "/subscriptions/sub_test_abc123",
                response_body: subscription_response("status" => "canceled"),)
      result = described_class.cancel("sub_test_abc123")
      expect(WebMock).to have_requested(:delete, "#{OnvoHelpers::TEST_API_BASE}/subscriptions/sub_test_abc123")
      expect(result.status).to eq("canceled")
    end
  end

  describe ".add_item" do
    it "POSTs to /subscriptions/:id/items" do
      stub_onvo(:post, "/subscriptions/sub_test_abc123/items", response_body: { "id" => "si_1" })
      result = described_class.add_item("sub_test_abc123", price_id: "price_789", quantity: 2)
      expect(WebMock).to have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/subscriptions/sub_test_abc123/items")
        .with(body: hash_including("priceId" => "price_789", "quantity" => 2))
      expect(result.id).to eq("si_1")
    end
  end

  describe ".update_item" do
    it "PATCHes /subscriptions/:id/items/:item_id" do
      stub_onvo(:patch, "/subscriptions/sub_test_abc123/items/si_1", response_body: { "id" => "si_1", "quantity" => 3 })
      result = described_class.update_item("sub_test_abc123", "si_1", quantity: 3)
      expect(result.quantity).to eq(3)
    end
  end

  describe ".remove_item" do
    it "DELETEs /subscriptions/:id/items/:item_id" do
      stub = stub_onvo(:delete, "/subscriptions/sub_test_abc123/items/si_1")
      described_class.remove_item("sub_test_abc123", "si_1")
      expect(stub).to have_been_requested
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
