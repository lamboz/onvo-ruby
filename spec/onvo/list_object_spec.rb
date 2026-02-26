# frozen_string_literal: true

RSpec.describe Onvo::ListObject do
  let(:items) do
    [
      { "id" => "cus_1", "name" => "Alice" },
      { "id" => "cus_2", "name" => "Bob" },
    ]
  end

  let(:list_data) do
    { "data" => items, "total" => 2, "limit" => 10, "offset" => 0, "has_more" => false }
  end

  subject(:list) { described_class.construct_from(list_data) }

  describe "#data" do
    it "returns an array" do
      expect(list.data).to be_an(Array)
    end

    it "wraps items as OnvoObjects" do
      expect(list.data.first).to be_a(Onvo::OnvoObject)
    end

    it "has the correct number of items" do
      expect(list.data.length).to eq(2)
    end
  end

  describe "#each" do
    it "yields each item" do
      ids = list.map(&:id)
      expect(ids).to eq(%w[cus_1 cus_2])
    end
  end

  describe "Enumerable" do
    it "supports map" do
      names = list.map(&:name)
      expect(names).to eq(%w[Alice Bob])
    end

    it "supports select" do
      expect(list.select { |item| item.id == "cus_1" }.length).to eq(1)
    end

    it "supports first" do
      expect(list.first.id).to eq("cus_1")
    end
  end

  describe "#has_more?" do
    it "returns false when the API sets has_more to false" do
      expect(list.has_more?).to be(false)
    end

    it "returns true when the API sets has_more to true" do
      data = list_data.merge("has_more" => true)
      expect(described_class.construct_from(data).has_more?).to be(true)
    end

    it "falls back to arithmetic when has_more is absent" do
      data = { "data" => items, "total" => 20, "limit" => 2, "offset" => 0 }
      list = described_class.construct_from(data)
      expect(list.has_more?).to be(true)
    end

    it "returns false from arithmetic when all items are returned" do
      data = { "data" => items, "total" => 2, "limit" => 10, "offset" => 0 }
      list = described_class.construct_from(data)
      expect(list.has_more?).to be(false)
    end
  end

  describe "#empty?" do
    it "returns false when there are items" do
      expect(list.empty?).to be(false)
    end

    it "returns true when data is empty" do
      empty_list = described_class.construct_from({ "data" => [] })
      expect(empty_list.empty?).to be(true)
    end
  end
end
