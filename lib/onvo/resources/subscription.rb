# frozen_string_literal: true

module Onvo
  # Subscriptions handle recurring billing for a Customer.
  #
  #   sub = Onvo::Subscription.create(
  #     customer_id: "cus_123",
  #     items: [{ price_id: "price_456", quantity: 1 }]
  #   )
  #   Onvo::Subscription.retrieve(sub.id)
  #   Onvo::Subscription.update(sub.id, metadata: { order_id: "6735" })
  #   Onvo::Subscription.cancel(sub.id, at_period_end: true)
  #   Onvo::Subscription.pause(sub.id)
  #   Onvo::Subscription.resume(sub.id)
  #   Onvo::Subscription.list(customer_id: "cus_123", status: "active")
  class Subscription < APIResource
    OBJECT_NAME = "subscription"

    extend Operations::Create
    extend Operations::Retrieve
    extend Operations::Update
    extend Operations::List

    # Cancel a subscription.
    # @param params [Hash] optional: at_period_end: true, cancellation_reason: "..."
    def self.cancel(id, client: default_client, **params)
      request(:post, "#{resource_url_for(id)}/cancel", params, client: client)
    end

    # Pause a subscription.
    # @param params [Hash] optional: resumes_at: <unix_timestamp>
    def self.pause(id, client: default_client, **params)
      request(:post, "#{resource_url_for(id)}/pause", params, client: client)
    end

    # Resume a paused subscription.
    def self.resume(id, client: default_client)
      request(:post, "#{resource_url_for(id)}/resume", {}, client: client)
    end
  end
end
