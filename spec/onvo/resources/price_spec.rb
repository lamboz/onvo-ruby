# frozen_string_literal: true

RSpec.describe Onvo::Price do
  describe ".create" do
    it "POSTs to /prices" do
      stub_onvo(:post, "/prices", response_body: price_response)
      result = described_class.create(
        product_id: "prod_test_abc123",
        unit_amount: 1000,
        currency: "USD",
        interval: "month",
      )
      expect(result.id).to eq("price_test_abc123")
    end

    it "converts product_id to camelCase productId" do
      stub_onvo(:post, "/prices", response_body: price_response)
      described_class.create(product_id: "prod_1", unit_amount: 500, currency: "USD")
      expect(WebMock).to have_requested(:post, "#{OnvoHelpers::TEST_API_BASE}/prices")
        .with(body: hash_including("productId" => "prod_1"))
    end
  end

  describe ".retrieve" do
    it "GETs /prices/:id" do
      stub_onvo(:get, "/prices/price_test_abc123", response_body: price_response)
      result = described_class.retrieve("price_test_abc123")
      expect(result.unit_amount).to eq(1000)
    end

    it "provides access to nested recurring object" do
      stub_onvo(:get, "/prices/price_test_abc123", response_body: price_response)
      result = described_class.retrieve("price_test_abc123")
      expect(result.recurring.interval).to eq("month")
    end
  end

  describe ".list" do
    it "GETs /prices and returns a ListObject" do
      stub_onvo(:get, "/prices", response_body: list_response(data: [price_response]))
      result = described_class.list
      expect(result).to be_a(Onvo::ListObject)
    end
  end
end
