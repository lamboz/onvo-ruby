# frozen_string_literal: true

RSpec.describe Onvo::Checkout::Session do
  describe ".create" do
    it "POSTs to /checkout/sessions/one-time-link" do
      stub_onvo(:post, "/checkout/sessions/one-time-link", response_body: checkout_session_response)
      result = described_class.create(
        line_items: [{ price_id: "price_456", quantity: 1 }],
        redirect_url: "https://example.com/success",
        cancel_url: "https://example.com/cancel",
      )
      expect(result.id).to eq("cs_test_abc123")
      expect(result.url).to eq("https://checkout.onvopay.com/pay/cs_test_abc123")
    end

    it "converts nested line item keys to camelCase" do
      stub_onvo(:post, "/checkout/sessions/one-time-link", response_body: checkout_session_response)
      described_class.create(line_items: [{ price_id: "price_1", quantity: 1 }], redirect_url: "u", cancel_url: "u")
      expect(WebMock).to(have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/checkout/sessions/one-time-link")
        .with { |req| JSON.parse(req.body).dig("lineItems", 0, "priceId") == "price_1" })
    end
  end

  describe ".retrieve" do
    it "GETs /checkout/sessions/:id" do
      stub_onvo(:get, "/checkout/sessions/cs_test_abc123", response_body: checkout_session_response)
      result = described_class.retrieve("cs_test_abc123")
      expect(result.status).to eq("open")
    end

    it "raises when id is blank" do
      expect { described_class.retrieve("") }.to raise_error(Onvo::InvalidRequestError)
    end
  end

  describe ".list" do
    it "GETs /checkout/sessions/one-time-link/account and returns a ListObject" do
      stub_onvo(:get, "/checkout/sessions/one-time-link/account",
                response_body: list_response(data: [checkout_session_response]),)
      result = described_class.list
      expect(result).to be_a(Onvo::ListObject)
    end
  end

  describe ".confirm" do
    it "POSTs to /checkout/sessions/:id/confirm" do
      stub_onvo(:post, "/checkout/sessions/cs_test_abc123/confirm",
                response_body: checkout_session_response("status" => "complete"),)
      result = described_class.confirm("cs_test_abc123", payment_method_id: "pm_123")
      expect(result.status).to eq("complete")
    end
  end

  describe ".update_line_item" do
    it "POSTs to /checkout/sessions/:id/line-item" do
      stub_onvo(:post, "/checkout/sessions/cs_test_abc123/line-item", response_body: checkout_session_response)
      result = described_class.update_line_item("cs_test_abc123", quantity: 2)
      expect(result.id).to eq("cs_test_abc123")
    end
  end

  describe ".update_customer" do
    it "PATCHes /checkout/sessions/:id/customer" do
      stub_onvo(:patch, "/checkout/sessions/cs_test_abc123/customer", response_body: checkout_session_response)
      result = described_class.update_customer("cs_test_abc123", email: "nueva@example.com")
      expect(result.id).to eq("cs_test_abc123")
    end
  end

  describe ".expire" do
    it "POSTs to /checkout/sessions/:id/expire" do
      stub_onvo(:post, "/checkout/sessions/cs_test_abc123/expire",
                response_body: checkout_session_response("status" => "expired"),)
      result = described_class.expire("cs_test_abc123")
      expect(result.status).to eq("expired")
    end
  end
end
