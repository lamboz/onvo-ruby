# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "openssl"

require_relative "onvo/version"
require_relative "onvo/util"
require_relative "onvo/configuration"
require_relative "onvo/errors"
require_relative "onvo/onvo_object"
require_relative "onvo/list_object"
require_relative "onvo/api_resource"
require_relative "onvo/client"

require_relative "onvo/operations/create"
require_relative "onvo/operations/retrieve"
require_relative "onvo/operations/update"
require_relative "onvo/operations/delete"
require_relative "onvo/operations/list"

require_relative "onvo/resources/customer"
require_relative "onvo/resources/payment_intent"
require_relative "onvo/resources/payment_method"
require_relative "onvo/resources/product"
require_relative "onvo/resources/price"
require_relative "onvo/resources/subscription"
require_relative "onvo/resources/refund"
require_relative "onvo/resources/webhook_endpoint"

require_relative "onvo/webhook"

# Onvo Ruby SDK
#
# Quick start:
#   Onvo.secret_key = "sk_live_..."
#   customer = Onvo::Customer.create(name: "Ana", email: "ana@example.com")
#
# Or with a configuration block:
#   Onvo.configure do |c|
#     c.secret_key = "sk_live_..."
#     c.sandbox    = false
#   end
module Onvo
  class << self
    # Get or set the API secret key directly.
    #   Onvo.secret_key = "sk_live_..."
    def secret_key
      configuration.secret_key
    end

    def secret_key=(value)
      configuration.secret_key = value
      # Reset cached client when the key changes.
      @default_client = nil
    end

    # Yield the Configuration object for block-style setup.
    #   Onvo.configure { |c| c.secret_key = "sk_live_..."; c.sandbox = false }
    def configure
      yield(configuration)
      @default_client = nil
    end

    # The global Configuration instance.
    def configuration
      @configuration ||= Configuration.new
    end

    # Reset the global configuration and client (useful in tests).
    def reset!
      @configuration = nil
      @default_client = nil
    end

    # The lazily-created, shared HTTP client.
    # Instantiates a new Client on first use (or after secret_key/configure changes).
    def default_client
      @default_client ||= Client.new(configuration)
    end
  end
end
