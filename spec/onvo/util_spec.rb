# frozen_string_literal: true

RSpec.describe Onvo::Util do
  describe ".to_camel_case" do
    it "converts snake_case to camelCase" do
      expect(described_class.to_camel_case("customer_id")).to eq("customerId")
    end

    it "handles single-word strings" do
      expect(described_class.to_camel_case("amount")).to eq("amount")
    end

    it "handles multiple underscores" do
      expect(described_class.to_camel_case("capture_method_type")).to eq("captureMethodType")
    end

    it "accepts symbols" do
      expect(described_class.to_camel_case(:customer_id)).to eq("customerId")
    end
  end

  describe ".to_snake_case" do
    it "converts camelCase to snake_case" do
      expect(described_class.to_snake_case("customerId")).to eq("customer_id")
    end

    it "handles single-word strings" do
      expect(described_class.to_snake_case("amount")).to eq("amount")
    end

    it "handles consecutive capitals" do
      expect(described_class.to_snake_case("HTMLParser")).to eq("html_parser")
    end

    it "handles already-snake_case strings" do
      expect(described_class.to_snake_case("customer_id")).to eq("customer_id")
    end
  end

  describe ".deep_camel_keys" do
    it "converts all hash keys to camelCase" do
      input = { "customer_id" => "cus_1", "payment_method" => "pm_1" }
      expect(described_class.deep_camel_keys(input)).to eq(
        "customerId" => "cus_1", "paymentMethod" => "pm_1",
      )
    end

    it "converts symbol keys" do
      input = { customer_id: "cus_1" }
      expect(described_class.deep_camel_keys(input)).to eq("customerId" => "cus_1")
    end

    it "recursively converts nested hashes" do
      input  = { "subscription_item" => { "price_id" => "price_1", "unit_amount" => 100 } }
      result = described_class.deep_camel_keys(input)
      expect(result).to eq("subscriptionItem" => { "priceId" => "price_1", "unitAmount" => 100 })
    end

    it "recursively converts hashes inside arrays" do
      input  = { "items" => [{ "price_id" => "price_1" }, { "price_id" => "price_2" }] }
      result = described_class.deep_camel_keys(input)
      expect(result).to eq("items" => [{ "priceId" => "price_1" }, { "priceId" => "price_2" }])
    end

    it "does NOT convert keys inside a metadata hash" do
      input  = { "customer_id" => "cus_1", "metadata" => { "my_custom_key" => "val" } }
      result = described_class.deep_camel_keys(input)
      expect(result["metadata"]).to eq("my_custom_key" => "val")
    end

    it "passes through non-Hash, non-Array values unchanged" do
      expect(described_class.deep_camel_keys("plain_string")).to eq("plain_string")
      expect(described_class.deep_camel_keys(42)).to eq(42)
    end
  end

  describe ".deep_snake_keys" do
    it "converts all hash keys to snake_case" do
      input = { "customerId" => "cus_1", "paymentMethod" => "pm_1" }
      expect(described_class.deep_snake_keys(input)).to eq(
        "customer_id" => "cus_1", "payment_method" => "pm_1",
      )
    end

    it "recursively converts nested hashes" do
      input  = { "subscriptionItem" => { "priceId" => "price_1" } }
      result = described_class.deep_snake_keys(input)
      expect(result).to eq("subscription_item" => { "price_id" => "price_1" })
    end

    it "does NOT convert keys inside a metadata hash" do
      input  = { "customerId" => "cus_1", "metadata" => { "myKey" => "val" } }
      result = described_class.deep_snake_keys(input)
      expect(result["metadata"]).to eq("myKey" => "val")
    end
  end

  describe ".encode_parameters" do
    it "returns a flat hash of string keys and values" do
      result = described_class.encode_parameters({ limit: 10, offset: 0 })
      expect(result).to eq("limit" => 10, "offset" => 0)
    end

    it "encodes nested hashes with bracket notation" do
      result = described_class.encode_parameters({ metadata: { key: "val" } })
      expect(result).to eq("metadata[key]" => "val")
    end

    it "encodes arrays with indexed bracket notation" do
      result = described_class.encode_parameters({ ids: %w[a b] })
      expect(result).to eq("ids[0]" => "a", "ids[1]" => "b")
    end
  end
end
