# frozen_string_literal: true

module Onvo
  # A PaymentIntent guides a payment through the collection process.
  #
  #   pi = Onvo::PaymentIntent.create(amount: 5000, currency: "USD")
  #   Onvo::PaymentIntent.retrieve(pi.id)
  #   Onvo::PaymentIntent.capture(pi.id)
  #   Onvo::PaymentIntent.cancel(pi.id)
  #   Onvo::PaymentIntent.list(limit: 10)
  #
  # Supported currencies: USD, CRC
  class PaymentIntent < APIResource
    OBJECT_NAME = "payment_intent"

    VALID_CURRENCIES = %w[USD CRC].freeze

    extend Operations::Retrieve
    extend Operations::List

    # Create a PaymentIntent.
    # @param params [Hash] :amount (integer, in cents), :currency (USD or CRC), and optional fields
    def self.create(client: default_client, **params)
      if params[:currency]
        validate_currency!(params[:currency])
        params = params.merge(currency: params[:currency].to_s.upcase)
      end
      request(:post, resource_url, params, client: client)
    end

    # Capture a previously authorized PaymentIntent.
    def self.capture(id, client: default_client, **params)
      request(:post, "#{resource_url_for(id)}/capture", params, client: client)
    end

    # Cancel a PaymentIntent.
    def self.cancel(id, client: default_client)
      request(:post, "#{resource_url_for(id)}/cancel", {}, client: client)
    end

    def self.validate_currency!(currency)
      return if VALID_CURRENCIES.include?(currency.to_s.upcase)

      raise InvalidRequestError,
            "Invalid currency '#{currency}'. Onvo supports: #{VALID_CURRENCIES.join(", ")}"
    end
    private_class_method :validate_currency!
  end
end
