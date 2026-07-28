# frozen_string_literal: true

RSpec.describe Onvo::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "defaults open_timeout to 30" do
      expect(config.open_timeout).to eq(30)
    end

    it "defaults read_timeout to 60" do
      expect(config.read_timeout).to eq(60)
    end

    it "defaults max_retries to 2" do
      expect(config.max_retries).to eq(2)
    end

    it "defaults logger to nil" do
      expect(config.logger).to be_nil
    end

    it "defaults publishable_key to nil" do
      expect(config.publishable_key).to be_nil
    end
  end

  describe "#api_base" do
    # ONVO's OpenAPI spec declares exactly one server (api.onvopay.com) —
    # there is no separate sandbox/dev host. Test vs. live mode comes
    # entirely from which API key prefix you use, not from a config flag
    # that points at a different URL.
    it "always returns the single real ONVO host, regardless of which key is configured" do
      expect(config.api_base).to eq("https://api.onvopay.com/v1")

      config.secret_key = "onvo_live_secret_key_whatever"
      expect(config.api_base).to eq("https://api.onvopay.com/v1")
    end
  end

  describe "env var fallback" do
    around do |example|
      original = ENV.fetch("ONVO_SECRET_KEY", nil)
      ENV["ONVO_SECRET_KEY"] = "sk_from_env"
      example.run
      ENV["ONVO_SECRET_KEY"] = original
    end

    it "reads secret_key from ONVO_SECRET_KEY" do
      expect(described_class.new.secret_key).to eq("sk_from_env")
    end
  end

  describe "publishable_key env var fallback" do
    around do |example|
      original = ENV.fetch("ONVO_PUBLISHABLE_KEY", nil)
      ENV["ONVO_PUBLISHABLE_KEY"] = "pk_from_env"
      example.run
      ENV["ONVO_PUBLISHABLE_KEY"] = original
    end

    it "reads publishable_key from ONVO_PUBLISHABLE_KEY" do
      expect(described_class.new.publishable_key).to eq("pk_from_env")
    end
  end

  describe "#validate!" do
    it "raises ConfigurationError when secret_key is nil" do
      config.secret_key = nil
      expect { config.validate! }.to raise_error(Onvo::ConfigurationError, /secret_key is required/)
    end

    it "raises ConfigurationError when secret_key is empty" do
      config.secret_key = "   "
      expect { config.validate! }.to raise_error(Onvo::ConfigurationError, /secret_key is required/)
    end

    it "does not raise when secret_key is set" do
      config.secret_key = "sk_test_valid"
      expect { config.validate! }.not_to raise_error
    end
  end
end
