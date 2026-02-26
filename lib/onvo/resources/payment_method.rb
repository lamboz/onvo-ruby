# frozen_string_literal: true

module Onvo
  # PaymentMethods represent saved or tokenized payment instruments
  # (cards, SINPE Movil, etc.) attached to a Customer.
  #
  #   Onvo::PaymentMethod.retrieve("pm_123")
  #   Onvo::PaymentMethod.list(customer_id: "cus_123")
  #   Onvo::PaymentMethod.attach("pm_123", customer_id: "cus_123")
  #   Onvo::PaymentMethod.detach("pm_123")
  class PaymentMethod < APIResource
    OBJECT_NAME = "payment_method"

    extend Operations::Retrieve
    extend Operations::List

    # Attach a PaymentMethod to a Customer.
    def self.attach(id, client: default_client, **params)
      request(:post, "#{resource_url_for(id)}/attach", params, client: client)
    end

    # Detach a PaymentMethod from its Customer.
    def self.detach(id, client: default_client)
      request(:post, "#{resource_url_for(id)}/detach", {}, client: client)
    end
  end
end
