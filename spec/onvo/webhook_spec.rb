# frozen_string_literal: true

RSpec.describe Onvo::Webhook do
  let(:webhook_secret) { "webhook_secret_abc123" }
  let(:payload) { '{"id":"evt_123","type":"payment-intent.succeeded","data":{}}' }

  describe ".construct_event" do
    context "with a matching secret header" do
      it "returns an OnvoObject" do
        event = described_class.construct_event(payload, webhook_secret, webhook_secret)
        expect(event).to be_a(Onvo::OnvoObject)
      end

      it "parses the event type" do
        event = described_class.construct_event(payload, webhook_secret, webhook_secret)
        expect(event.type).to eq("payment-intent.succeeded")
      end

      it "converts camelCase keys in the event payload" do
        pl    = '{"id":"evt_1","type":"test","someKey":"val"}'
        event = described_class.construct_event(pl, webhook_secret, webhook_secret)
        expect(event.some_key).to eq("val")
      end
    end

    context "with a mismatched secret header" do
      it "raises SignatureVerificationError" do
        expect { described_class.construct_event(payload, "webhook_secret_wrong", webhook_secret) }
          .to raise_error(Onvo::SignatureVerificationError, /mismatch/)
      end
    end

    context "with a missing secret header" do
      it "raises SignatureVerificationError for nil header" do
        expect { described_class.construct_event(payload, nil, webhook_secret) }
          .to raise_error(Onvo::SignatureVerificationError, /No webhook secret header/)
      end

      it "raises SignatureVerificationError for an empty header" do
        expect { described_class.construct_event(payload, "  ", webhook_secret) }
          .to raise_error(Onvo::SignatureVerificationError, /No webhook secret header/)
      end
    end

    context "with no configured secret" do
      it "raises SignatureVerificationError" do
        expect { described_class.construct_event(payload, webhook_secret, nil) }
          .to raise_error(Onvo::SignatureVerificationError, /No webhook secret configured/)
      end
    end
  end

  describe Onvo::Webhook::Signature do
    describe ".verify_header!" do
      it "returns nil when the header matches the configured secret" do
        expect(described_class.verify_header!(webhook_secret, webhook_secret)).to be_nil
      end

      it "raises when the header doesn't match" do
        expect { described_class.verify_header!("webhook_secret_other", webhook_secret) }
          .to raise_error(Onvo::SignatureVerificationError, /mismatch/)
      end

      it "raises when the header and secret differ in length" do
        expect { described_class.verify_header!("short", webhook_secret) }
          .to raise_error(Onvo::SignatureVerificationError, /mismatch/)
      end
    end
  end
end
