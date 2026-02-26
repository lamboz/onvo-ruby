# frozen_string_literal: true

RSpec.describe Onvo::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "defaults to sandbox mode" do
      config_without_env = described_class.new
      # When ONVO_SANDBOX is not set, defaults to sandbox=true
      expect(config_without_env.sandbox).to be(true)
    end

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
  end

  describe "#api_base" do
    it "returns the sandbox URL when sandbox is true" do
      config.sandbox = true
      expect(config.api_base).to eq("https://api.dev.onvopay.com/v1")
    end

    it "returns the production URL when sandbox is false" do
      config.sandbox = false
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

  describe "ONVO_SANDBOX env var" do
    around do |example|
      original = ENV.fetch("ONVO_SANDBOX", nil)
      example.run
      ENV["ONVO_SANDBOX"] = original
    end

    it "sets sandbox=false when ONVO_SANDBOX=false" do
      ENV["ONVO_SANDBOX"] = "false"
      expect(described_class.new.sandbox).to be(false)
    end

    it "sets sandbox=true when ONVO_SANDBOX=true" do
      ENV["ONVO_SANDBOX"] = "true"
      expect(described_class.new.sandbox).to be(true)
    end

    it "sets sandbox=true when ONVO_SANDBOX=1" do
      ENV["ONVO_SANDBOX"] = "1"
      expect(described_class.new.sandbox).to be(true)
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
