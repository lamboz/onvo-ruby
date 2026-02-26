# frozen_string_literal: true

RSpec.describe Onvo::WebhookEndpoint do
  describe ".create" do
    it "POSTs to /webhooks" do
      stub_onvo(:post, "/webhooks", response_body: webhook_endpoint_response)
      result = described_class.create(
        url: "https://example.com/webhooks",
        events: ["payment_intent.succeeded"],
      )
      expect(result.id).to eq("we_test_abc123")
    end
  end

  describe ".retrieve" do
    it "GETs /webhooks/:id" do
      stub_onvo(:get, "/webhooks/we_test_abc123", response_body: webhook_endpoint_response)
      result = described_class.retrieve("we_test_abc123")
      expect(result.url).to eq("https://example.com/webhooks")
    end
  end

  describe ".update" do
    it "PATCHes /webhooks/:id" do
      updated = webhook_endpoint_response("events" => ["subscription.created"])
      stub_onvo(:patch, "/webhooks/we_test_abc123", response_body: updated)
      result = described_class.update("we_test_abc123", events: ["subscription.created"])
      expect(result.events).to include("subscription.created")
    end
  end

  describe ".delete" do
    it "DELETEs /webhooks/:id" do
      stub_onvo(:delete, "/webhooks/we_test_abc123", response_body: deleted_response("we_test_abc123"))
      result = described_class.delete("we_test_abc123")
      expect(result.deleted).to be(true)
    end
  end

  describe ".list" do
    it "GETs /webhooks and returns a ListObject" do
      stub_onvo(:get, "/webhooks", response_body: list_response(data: [webhook_endpoint_response]))
      result = described_class.list
      expect(result).to be_a(Onvo::ListObject)
      expect(result.first.url).to eq("https://example.com/webhooks")
    end
  end
end
