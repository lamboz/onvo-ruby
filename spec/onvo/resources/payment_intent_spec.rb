# frozen_string_literal: true

RSpec.describe Onvo::PaymentIntent do
  describe ".create" do
    it "POSTs to /payment-intents" do
      stub_onvo(:post, "/payment-intents", response_body: payment_intent_response)
      result = described_class.create(amount: 1000, currency: "USD")
      expect(result.id).to eq("pi_test_abc123")
    end

    it "upcases the currency" do
      stub_onvo(:post, "/payment-intents", response_body: payment_intent_response)
      described_class.create(amount: 1000, currency: "usd")
      expect(WebMock).to have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/payment-intents")
        .with(body: hash_including("currency" => "USD"))
    end

    it "raises InvalidRequestError for an unsupported currency" do
      expect { described_class.create(amount: 1000, currency: "EUR") }
        .to raise_error(Onvo::InvalidRequestError, /EUR/)
    end

    it "accepts CRC as a valid currency" do
      stub_onvo(:post, "/payment-intents",
                response_body: payment_intent_response("currency" => "CRC"),)
      expect { described_class.create(amount: 1000, currency: "CRC") }.not_to raise_error
    end
  end

  describe ".retrieve" do
    it "GETs /payment-intents/:id" do
      stub_onvo(:get, "/payment-intents/pi_test_abc123", response_body: payment_intent_response)
      result = described_class.retrieve("pi_test_abc123")
      expect(result.amount).to eq(1000)
    end
  end

  describe ".confirm" do
    it "POSTs to /payment-intents/:id/confirm with paymentMethodId" do
      stub = stub_onvo(:post, "/payment-intents/pi_test_abc123/confirm",
                       response_body: payment_intent_response("status" => "requires_action"),)
      result = described_class.confirm("pi_test_abc123", payment_method_id: "pm_test_abc123")
      expect(stub).to have_been_requested
      expect(WebMock).to have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/payment-intents/pi_test_abc123/confirm")
        .with(body: hash_including("paymentMethodId" => "pm_test_abc123"))
      expect(result.status).to eq("requires_action")
    end

    it "forwards optional params (e.g. return_url for 3DS)" do
      stub_onvo(:post, "/payment-intents/pi_test_abc123/confirm", response_body: payment_intent_response)
      described_class.confirm(
        "pi_test_abc123",
        payment_method_id: "pm_test_abc123",
        return_url: "https://example.com/return",
      )
      expect(WebMock).to have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/payment-intents/pi_test_abc123/confirm")
        .with(body: hash_including("returnUrl" => "https://example.com/return"))
    end
  end

  describe ".capture" do
    it "POSTs to /payment-intents/:id/capture" do
      stub = stub_onvo(:post, "/payment-intents/pi_test_abc123/capture",
                       response_body: payment_intent_response("status" => "succeeded"),)
      result = described_class.capture("pi_test_abc123")
      expect(stub).to have_been_requested
      expect(result.status).to eq("succeeded")
    end
  end

  describe ".cancel" do
    it "POSTs to /payment-intents/:id/cancel" do
      stub = stub_onvo(:post, "/payment-intents/pi_test_abc123/cancel",
                       response_body: payment_intent_response("status" => "canceled"),)
      result = described_class.cancel("pi_test_abc123")
      expect(stub).to have_been_requested
      expect(result.status).to eq("canceled")
    end
  end

  describe ".list" do
    it "GETs /payment-intents and returns a ListObject" do
      stub_onvo(:get, "/payment-intents",
                response_body: list_response(data: [payment_intent_response]),)
      result = described_class.list
      expect(result).to be_a(Onvo::ListObject)
    end
  end
end
