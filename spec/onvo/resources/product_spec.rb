# frozen_string_literal: true

RSpec.describe Onvo::Product do
  describe ".create" do
    it "POSTs to /products" do
      stub_onvo(:post, "/products", response_body: product_response)
      result = described_class.create(name: "Pro Plan", description: "Full features")
      expect(result.id).to eq("prod_test_abc123")
      expect(result.name).to eq("Test Product")
    end
  end

  describe ".retrieve" do
    it "GETs /products/:id" do
      stub_onvo(:get, "/products/prod_test_abc123", response_body: product_response)
      result = described_class.retrieve("prod_test_abc123")
      expect(result.active).to be(true)
    end
  end

  describe ".list" do
    it "GETs /products and returns a ListObject" do
      stub_onvo(:get, "/products", response_body: list_response(data: [product_response]))
      result = described_class.list
      expect(result).to be_a(Onvo::ListObject)
      expect(result.first.name).to eq("Test Product")
    end
  end
end
