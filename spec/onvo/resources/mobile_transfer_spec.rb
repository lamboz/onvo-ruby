# frozen_string_literal: true

RSpec.describe Onvo::MobileTransfer do
  describe ".list" do
    it "GETs /mobile-transfers/list, not the bare collection path" do
      stub = stub_onvo(:get, "/mobile-transfers/list", response_body: list_response(data: [mobile_transfer_response]))
      result = described_class.list
      expect(stub).to have_been_requested
      expect(result).to be_a(Onvo::ListObject)
      expect(result.data.first.id).to eq("mt_test_abc123")
    end

    it "snake_cases the irregular SINPERefNumber response field to sinpe_ref_number" do
      stub_onvo(:get, "/mobile-transfers/list", response_body: list_response(data: [mobile_transfer_response]))
      result = described_class.list
      expect(result.data.first.sinpe_ref_number).to eq("2025121616183220990502000")
    end

    it "exposes a nil payment_intent_id for an unlinked transfer" do
      stub_onvo(:get, "/mobile-transfers/list",
                response_body: list_response(data: [mobile_transfer_response("payment_intent_id" => nil)]),)
      result = described_class.list
      expect(result.data.first.payment_intent_id).to be_nil
    end

    it "forwards ordinary filters (status, origin_id) as query params" do
      stub_request(:get, "#{OnvoHelpers::TEST_API_BASE}/mobile-transfers/list")
        .with(query: hash_including("status" => "charge_not_found", "originId" => "01-1393-1919"))
        .to_return(status: 200, body: list_response(data: []).to_json,
                   headers: { "Content-Type" => "application/json" },)
      result = described_class.list(status: "charge_not_found", origin_id: "01-1393-1919")
      expect(result).to be_a(Onvo::ListObject)
    end

    it "sends sinpe_ref_number as the literal SINPERefNumber query param" do
      stub_request(:get, "#{OnvoHelpers::TEST_API_BASE}/mobile-transfers/list")
        .with(query: hash_including("SINPERefNumber" => "2025121616183220990502000"))
        .to_return(status: 200, body: list_response(data: []).to_json,
                   headers: { "Content-Type" => "application/json" },)
      result = described_class.list(sinpe_ref_number: "2025121616183220990502000")
      expect(result).to be_a(Onvo::ListObject)
    end
  end
end
