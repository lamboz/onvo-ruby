# frozen_string_literal: true

module Onvo
  # Base class for all Onvo API resources.
  #
  # Subclasses declare an OBJECT_NAME constant which drives URL generation:
  #
  #   class Customer < APIResource
  #     OBJECT_NAME = "customer"
  #   end
  #
  # URL mapping rules:
  #   "customer"        => /customers
  #   "payment_intent"  => /payment-intents
  #   "webhook"         => /webhooks
  #
  # Override resource_url in a subclass if the automatic mapping is wrong.
  class APIResource < OnvoObject
    # Returns the collection URL for this resource (e.g. "/customers").
    def self.resource_url
      "/#{self::OBJECT_NAME.tr("_", "-")}s"
    end

    # Returns the URL for a specific resource instance (e.g. "/customers/cus_123").
    def self.resource_url_for(id)
      raise InvalidRequestError, "id is required" if id.nil? || id.to_s.strip.empty?

      "#{resource_url}/#{id}"
    end

    # Delegates to the module-level default client. Resources call this
    # to make requests and can also accept a per-request :client keyword.
    def self.default_client
      Onvo.default_client
    end

    # Execute an HTTP request via the given client.
    def self.request(method, url, params = {}, client: default_client)
      client.public_send(method, url, params)
    end
  end
end
