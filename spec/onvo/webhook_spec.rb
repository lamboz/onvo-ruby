# frozen_string_literal: true

RSpec.describe Onvo::Webhook do
  let(:secret)    { "whsec_test_secret_key_abc123" }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:payload)   { '{"id":"evt_123","type":"payment_intent.succeeded","data":{}}' }

  def build_header(ts_val, sig_val)
    "t=#{ts_val},v1=#{sig_val}"
  end

  def valid_sig(ts_val = timestamp, payload_val = payload)
    Onvo::Webhook::Signature.compute_signature(ts_val, payload_val, secret)
  end

  def valid_header(ts_val = timestamp, payload_val = payload)
    build_header(ts_val, valid_sig(ts_val, payload_val))
  end

  describe ".construct_event" do
    context "with a valid signature" do
      it "returns an OnvoObject" do
        event = described_class.construct_event(payload, valid_header, secret)
        expect(event).to be_a(Onvo::OnvoObject)
      end

      it "parses the event type" do
        event = described_class.construct_event(payload, valid_header, secret)
        expect(event.type).to eq("payment_intent.succeeded")
      end

      it "converts camelCase keys in the event payload" do
        pl    = '{"id":"evt_1","type":"test","someKey":"val"}'
        event = described_class.construct_event(pl, valid_header(timestamp, pl), secret)
        expect(event.some_key).to eq("val")
      end
    end

    context "with an invalid signature" do
      it "raises SignatureVerificationError" do
        bad_header = build_header(timestamp, "badhex000")
        expect { described_class.construct_event(payload, bad_header, secret) }
          .to raise_error(Onvo::SignatureVerificationError, /Signature mismatch/)
      end
    end

    context "with a missing signature header" do
      it "raises SignatureVerificationError for nil header" do
        expect { described_class.construct_event(payload, nil, secret) }
          .to raise_error(Onvo::SignatureVerificationError, /No signature header/)
      end

      it "raises SignatureVerificationError for empty header" do
        expect { described_class.construct_event(payload, "  ", secret) }
          .to raise_error(Onvo::SignatureVerificationError, /No signature header/)
      end
    end

    context "with a missing or empty secret" do
      it "raises SignatureVerificationError for nil secret" do
        expect { described_class.construct_event(payload, valid_header, nil) }
          .to raise_error(Onvo::SignatureVerificationError, /No webhook secret/)
      end
    end

    context "replay protection" do
      it "raises SignatureVerificationError when timestamp is too old" do
        old_ts = (Time.now.to_i - 301).to_s
        header = build_header(old_ts, valid_sig(old_ts))
        expect { described_class.construct_event(payload, header, secret, tolerance: 300) }
          .to raise_error(Onvo::SignatureVerificationError, /too old/)
      end

      it "accepts events within the tolerance window" do
        recent_ts = (Time.now.to_i - 100).to_s
        header    = build_header(recent_ts, valid_sig(recent_ts))
        expect { described_class.construct_event(payload, header, secret, tolerance: 300) }
          .not_to raise_error
      end

      it "skips timestamp check when tolerance is nil" do
        old_ts = (Time.now.to_i - 10_000).to_s
        header = build_header(old_ts, valid_sig(old_ts))
        expect { described_class.construct_event(payload, header, secret, tolerance: nil) }
          .not_to raise_error
      end
    end
  end

  describe Onvo::Webhook::Signature do
    describe ".compute_signature" do
      it "produces a deterministic hex string" do
        sig1 = described_class.compute_signature("12345", "payload", "secret")
        sig2 = described_class.compute_signature("12345", "payload", "secret")
        expect(sig1).to eq(sig2)
      end

      it "produces different signatures for different payloads" do
        sig1 = described_class.compute_signature("12345", "payload_a", "secret")
        sig2 = described_class.compute_signature("12345", "payload_b", "secret")
        expect(sig1).not_to eq(sig2)
      end

      it "produces different signatures for different timestamps" do
        sig1 = described_class.compute_signature("1", "payload", "secret")
        sig2 = described_class.compute_signature("2", "payload", "secret")
        expect(sig1).not_to eq(sig2)
      end
    end

    describe ".verify_header!" do
      it "returns nil for a valid header" do
        result = described_class.verify_header!(payload, valid_header, secret)
        expect(result).to be_nil
      end

      it "raises for a malformed header (no t= part)" do
        expect { described_class.verify_header!(payload, "v1=abc123", secret) }
          .to raise_error(Onvo::SignatureVerificationError, /Malformed/)
      end

      it "raises for a malformed header (no v1= part)" do
        expect { described_class.verify_header!(payload, "t=12345", secret) }
          .to raise_error(Onvo::SignatureVerificationError, /Malformed/)
      end
    end
  end
end
