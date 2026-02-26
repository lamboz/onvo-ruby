# frozen_string_literal: true

RSpec.describe Onvo::OnvoObject do
  let(:data) do
    {
      "id" => "obj_123",
      "name" => "Test",
      "amount" => 1000,
      "nested" => { "key" => "value" },
      "list" => [{ "id" => "item_1" }, { "id" => "item_2" }],
      "metadata" => { "order_id" => "ord_1" },
    }
  end

  subject(:obj) { described_class.construct_from(data) }

  describe ".construct_from" do
    it "returns an OnvoObject" do
      expect(obj).to be_a(described_class)
    end

    it "handles an empty hash" do
      expect(described_class.construct_from({})).to be_a(described_class)
    end
  end

  describe "dynamic attribute access" do
    it "provides dot-notation access" do
      expect(obj.id).to eq("obj_123")
      expect(obj.name).to eq("Test")
      expect(obj.amount).to eq(1000)
    end

    it "provides bracket access" do
      expect(obj["id"]).to eq("obj_123")
    end

    it "raises NoMethodError for unknown attributes" do
      expect { obj.nonexistent_field }.to raise_error(NoMethodError)
    end

    it "responds true to respond_to? for known attributes" do
      expect(obj.respond_to?(:id)).to be(true)
    end

    it "responds false to respond_to? for unknown attributes" do
      expect(obj.respond_to?(:nonexistent_field)).to be(false)
    end
  end

  describe "nested object wrapping" do
    it "wraps nested hashes as OnvoObjects" do
      expect(obj.nested).to be_a(described_class)
      expect(obj.nested.key).to eq("value")
    end

    it "wraps arrays of hashes as arrays of OnvoObjects" do
      expect(obj.list).to be_an(Array)
      expect(obj.list.first).to be_a(described_class)
      expect(obj.list.first.id).to eq("item_1")
    end
  end

  describe "#to_h" do
    it "returns a plain Ruby hash" do
      result = obj.to_h
      expect(result).to be_a(Hash)
    end

    it "recursively converts nested OnvoObjects" do
      result = obj.to_h
      expect(result["nested"]).to be_a(Hash)
      expect(result["nested"]["key"]).to eq("value")
    end

    it "round-trips: construct_from(hash).to_h matches the original hash" do
      simple = { "id" => "1", "name" => "Test" }
      expect(described_class.construct_from(simple).to_h).to eq(simple)
    end
  end

  describe "#==" do
    it "is equal to another OnvoObject with the same data" do
      expect(obj).to eq(described_class.construct_from(data))
    end

    it "is not equal to an OnvoObject with different data" do
      expect(obj).not_to eq(described_class.construct_from(data.merge("id" => "other")))
    end
  end

  describe "#inspect" do
    it "includes the class name" do
      expect(obj.inspect).to include("OnvoObject")
    end

    it "includes the id when present" do
      expect(obj.inspect).to include("obj_123")
    end
  end
end
