# frozen_string_literal: true

module Onvo
  # A Refund represents a reversal of a previously confirmed PaymentIntent.
  #
  # Refunds are always created as children of a PaymentIntent:
  #
  #   refund = Onvo::Refund.create("pi_test_abc123", amount: 5000, reason: "requested_by_customer")
  #   Onvo::Refund.retrieve(refund.id)
  #   Onvo::Refund.list
  #
  # Partial refunds are supported by supplying an +amount+ less than the
  # original PaymentIntent amount. Omitting +amount+ issues a full refund.
  class Refund < APIResource
    OBJECT_NAME = "refund"

    VALID_REASONS = %w[duplicate fraudulent requested_by_customer].freeze

    extend Operations::Retrieve
    extend Operations::List

    # Create a refund for a PaymentIntent.
    #
    # @param payment_intent_id [String] the ID of the PaymentIntent to refund
    # @param amount [Integer, nil] amount in cents; omit for a full refund
    # @param reason [String, nil] one of: duplicate, fraudulent, requested_by_customer
    # @param client [Onvo::Client] optional; defaults to Onvo.default_client
    def self.create(payment_intent_id, client: default_client, **params)
      validate_payment_intent_id!(payment_intent_id)
      validate_reason!(params[:reason]) if params[:reason]

      request(:post, "/payment-intents/#{payment_intent_id}/refunds", params, client: client)
    end

    def self.validate_payment_intent_id!(id)
      raise InvalidRequestError, "payment_intent_id cannot be blank" if id.nil? || id.to_s.strip.empty?
    end
    private_class_method :validate_payment_intent_id!

    def self.validate_reason!(reason)
      return if VALID_REASONS.include?(reason.to_s)

      raise InvalidRequestError,
            "Invalid reason '#{reason}'. Valid reasons: #{VALID_REASONS.join(", ")}"
    end
    private_class_method :validate_reason!
  end
end
