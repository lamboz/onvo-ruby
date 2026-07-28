# frozen_string_literal: true

module Onvo
  module Checkout
    # Checkout Sessions are ONVO's hosted checkout flow: create a session
    # (pointing at a recurring price to start a subscription, or a
    # fixed-amount line item for a one-time charge), redirect the customer
    # to its `url`, then trust the `checkout-session.succeeded` webhook —
    # not the redirect — as the source of truth that payment completed.
    #
    #   session = Onvo::Checkout::Session.create(
    #     line_items:   [{ price_id: "price_456", quantity: 1 }],
    #     customer_email: "ana@example.com",
    #     redirect_url: "https://example.com/success",
    #     cancel_url:   "https://example.com/cancel",
    #   )
    #   session.url    # => "https://checkout.onvopay.com/pay/..."
    #   session.status # => "open"
    #
    #   Onvo::Checkout::Session.retrieve(session.id)
    #   Onvo::Checkout::Session.list
    #   Onvo::Checkout::Session.update_customer(session.id, email: "nueva@example.com")
    #   Onvo::Checkout::Session.expire(session.id)
    class Session < APIResource
      OBJECT_NAME = "checkout_session"

      BASE_PATH = "/checkout/sessions"

      extend Operations::Create
      extend Operations::Retrieve

      # Sessions are created under a distinct path from where they're read back.
      def self.resource_url
        "#{BASE_PATH}/one-time-link"
      end

      def self.resource_url_for(id)
        raise InvalidRequestError, "id is required" if id.nil? || id.to_s.strip.empty?

        "#{BASE_PATH}/#{id}"
      end

      def self.list(client: default_client, **filters)
        request(:get, "#{BASE_PATH}/one-time-link/account", filters, client: client)
      end

      # Confirm a Checkout session with the customer's selected payment method.
      def self.confirm(id, client: default_client, **params)
        request(:post, "#{resource_url_for(id)}/confirm", params, client: client)
      end

      # Update the line item of an open Checkout session.
      def self.update_line_item(id, client: default_client, **params)
        request(:post, "#{resource_url_for(id)}/line-item", params, client: client)
      end

      # Update the customer contact details of an open Checkout session.
      def self.update_customer(id, client: default_client, **params)
        request(:patch, "#{resource_url_for(id)}/customer", params, client: client)
      end

      # Expire a Checkout session before its default expiry.
      def self.expire(id, client: default_client)
        request(:post, "#{resource_url_for(id)}/expire", {}, client: client)
      end
    end
  end
end
