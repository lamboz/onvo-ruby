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
  #     c.sandbox    = false
  #   end
  class Configuration
    SANDBOX_BASE    = "https://api.dev.onvopay.com/v1"
    PRODUCTION_BASE = "https://api.onvopay.com/v1"

    attr_accessor :secret_key, :open_timeout, :read_timeout, :max_retries, :logger, :sandbox

    def initialize
      @secret_key   = ENV.fetch("ONVO_SECRET_KEY", nil)
      env           = ENV.fetch("ONVO_SANDBOX", nil)
      @sandbox      = env.nil? || %w[true 1 yes].include?(env.downcase)
      @open_timeout = 30
      @read_timeout = 60
      @max_retries  = 2
      @logger       = nil
    end

    # Returns the API base URL depending on sandbox mode.
    # If you need a custom URL, subclass or monkey-patch this method.
    def api_base
      @sandbox ? SANDBOX_BASE : PRODUCTION_BASE
    end

    # Raise ConfigurationError if the configuration is not usable.
    def validate!
      raise ConfigurationError, "secret_key is required" if secret_key.nil? || secret_key.strip.empty?
    end
  end
end
