# frozen_string_literal: true

module Onvo
  # Holds all configuration for the Onvo SDK.
  #
  # Configure globally:
  #   Onvo.secret_key = "sk_live_..."
  #
  # Or use a block:
  #   Onvo.configure do |c|
  #     c.secret_key = "sk_live_..."
  #   end
  class Configuration
    # ONVO's OpenAPI spec (docs.onvopay.com/openapi.yaml) declares exactly
    # one server: https://api.onvopay.com. There is no separate sandbox/dev
    # host — test vs. live mode is determined entirely by which API key
    # prefix you use (onvo_test_secret_key_ / onvo_live_secret_key_), same
    # as the publishable key. A prior version of this SDK assumed a
    # Stripe-style dual-host split (api.dev.onvopay.com) that doesn't exist
    # in ONVO's real API — every request sent while "sandbox: true" was
    # silently going to a host ONVO never serves.
    API_BASE = "https://api.onvopay.com/v1"

    attr_accessor :secret_key, :publishable_key, :open_timeout, :read_timeout, :max_retries, :logger

    def initialize
      @secret_key      = ENV.fetch("ONVO_SECRET_KEY", nil)
      # The publishable key is safe to expose to the browser — it's what the
      # client-side SDK (see README "Subscriptions with client-side card
      # entry") needs to render its embedded card component. Distinct from
      # secret_key, which must never leave the server.
      @publishable_key = ENV.fetch("ONVO_PUBLISHABLE_KEY", nil)
      @open_timeout    = 30
      @read_timeout    = 60
      @max_retries     = 2
      @logger          = nil
    end

    # The API base URL. Always the same host — see API_BASE above.
    def api_base
      API_BASE
    end

    # Raise ConfigurationError if the configuration is not usable.
    def validate!
      raise ConfigurationError, "secret_key is required" if secret_key.nil? || secret_key.strip.empty?
    end
  end
end
