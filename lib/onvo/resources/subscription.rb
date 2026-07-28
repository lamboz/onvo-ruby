# frozen_string_literal: true

module Onvo
  # Subscriptions ("cargos recurrentes") handle recurring billing for a Customer.
  #
  #   sub = Onvo::Subscription.create(
  #     customer_id: "cus_123",
  #     items: [{ price_id: "price_456", quantity: 1 }],
  #     trial_period_days: 14,
  #   )
  #   Onvo::Subscription.retrieve(sub.id)
  #   Onvo::Subscription.update(sub.id, metadata: { order_id: "6735" })
  #   Onvo::Subscription.update(sub.id, cancel_at_period_end: true)
  #   Onvo::Subscription.confirm(sub.id, payment_method_id: "pm_123")
  #   Onvo::Subscription.cancel(sub.id)
  #   Onvo::Subscription.add_item(sub.id, price_id: "price_789", quantity: 1)
  #   Onvo::Subscription.update_item(sub.id, "si_1", quantity: 3)
  #   Onvo::Subscription.remove_item(sub.id, "si_1")
  #   Onvo::Subscription.list(customer_id: "cus_123", status: "active")
  class Subscription < APIResource
    OBJECT_NAME = "subscription"

    extend Operations::Create
    extend Operations::Retrieve
    extend Operations::Update
    extend Operations::List

    # Cancel (immediately and permanently end) a subscription.
    # To cancel at the end of the current billing period instead, use
    # `update(id, cancel_at_period_end: true)`.
    def self.cancel(id, client: default_client)
      request(:delete, resource_url_for(id), {}, client: client)
    end

    # Confirm a subscription created with payment_behavior: "allow_incomplete".
    # @param params [Hash] typically: payment_method_id: "..."
    def self.confirm(id, client: default_client, **params)
      request(:post, "#{resource_url_for(id)}/confirm", params, client: client)
    end

    # Add a recurring price item to an existing subscription.
    # @param params [Hash] price_id: "...", quantity: <integer>
    def self.add_item(id, client: default_client, **params)
      request(:post, "#{resource_url_for(id)}/items", params, client: client)
    end

    # Update a subscription item (e.g. its quantity).
    def self.update_item(id, item_id, client: default_client, **params)
      request(:patch, "#{resource_url_for(id)}/items/#{item_id}", params, client: client)
    end

    # Remove an item from a subscription.
    def self.remove_item(id, item_id, client: default_client)
      request(:delete, "#{resource_url_for(id)}/items/#{item_id}", {}, client: client)
    end
  end
end
