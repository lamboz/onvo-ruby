# frozen_string_literal: true

RSpec.describe Onvo::Refund do
  describe ".create" do
    it "POSTs to /payment-intents/:id/refunds" do
      stub_onvo(:post, "/payment-intents/pi_test_abc123/refunds", response_body: refund_response)
      result = described_class.create("pi_test_abc123", amount: 500)
      expect(result.id).to eq("re_test_abc123")
      expect(result.payment_intent_id).to eq("pi_test_abc123")
    end

    it "issues a full refund when amount is omitted" do
      stub_onvo(:post, "/payment-intents/pi_test_abc123/refunds", response_body: refund_response)
      described_class.create("pi_test_abc123")
      # Client omits body entirely when params are empty — no amount key in request
      expect(WebMock).to have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/payment-intents/pi_test_abc123/refunds")
        .with { |req| req.body.nil? || req.body.empty? }
    end

    it "passes reason to the API" do
      stub_onvo(:post, "/payment-intents/pi_test_abc123/refunds",
                response_body: refund_response("reason" => "fraudulent"))
      described_class.create("pi_test_abc123", reason: "fraudulent")
      expect(WebMock).to have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/payment-intents/pi_test_abc123/refunds")
        .with(body: hash_including("reason" => "fraudulent"))
    end

    it "raises InvalidRequestError when payment_intent_id is blank" do
      expect { described_class.create("") }
        .to raise_error(Onvo::InvalidRequestError, /payment_intent_id cannot be blank/)
    end

    it "raises InvalidRequestError when payment_intent_id is nil" do
      expect { described_class.create(nil) }
        .to raise_error(Onvo::InvalidRequestError, /payment_intent_id cannot be blank/)
    end

    it "raises InvalidRequestError for an invalid reason" do
      expect { described_class.create("pi_test_abc123", reason: "i_changed_my_mind") }
        .to raise_error(Onvo::InvalidRequestError, /i_changed_my_mind/)
    end

    it "accepts all valid reasons without raising" do
      %w[duplicate fraudulent requested_by_customer].each do |reason|
        stub_onvo(:post, "/payment-intents/pi_test_abc123/refunds",
                  response_body: refund_response("reason" => reason))
        expect { described_class.create("pi_test_abc123", reason: reason) }.not_to raise_error
      end
    end
  end

  describe ".retrieve" do
    it "GETs /refunds/:id" do
      stub_onvo(:get, "/refunds/re_test_abc123", response_body: refund_response)
      result = described_class.retrieve("re_test_abc123")
      expect(result.id).to eq("re_test_abc123")
      expect(result.status).to eq("succeeded")
    end
  end

  describe ".list" do
    it "GETs /refunds and returns a ListObject" do
      stub_onvo(:get, "/refunds", response_body: list_response(data: [refund_response]))
      result = described_class.list
      expect(result).to be_a(Onvo::ListObject)
      expect(result.data.first.id).to eq("re_test_abc123")
    end

    it "forwards filter params as query string" do
      stub_request(:get, "#{OnvoHelpers::TEST_API_BASE}/refunds")
        .with(query: hash_including("limit" => "5"))
        .to_return(status: 200, body: list_response(data: []).to_json,
                   headers: { "Content-Type" => "application/json" })
      result = described_class.list(limit: 5)
      expect(result).to be_a(Onvo::ListObject)
    end
  end
end
