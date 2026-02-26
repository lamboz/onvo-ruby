# frozen_string_literal: true

module Onvo
  # WebhookEndpoints configure where Onvo sends event notifications.
  #
  #   ep = Onvo::WebhookEndpoint.create(
  #     url: "https://example.com/webhooks",
  #     events: ["payment_intent.succeeded", "subscription.created"]
  #   )
  #   Onvo::WebhookEndpoint.retrieve(ep.id)
  #   Onvo::WebhookEndpoint.update(ep.id, events: ["payment_intent.succeeded"])
  #   Onvo::WebhookEndpoint.delete(ep.id)
  #   Onvo::WebhookEndpoint.list
  class WebhookEndpoint < APIResource
    # The Onvo API path for webhooks is /webhooks (not /webhook-endpoints).
    OBJECT_NAME = "webhook"

    extend Operations::Create
    extend Operations::Retrieve
    extend Operations::Update
    extend Operations::Delete
    extend Operations::List
  end
end
