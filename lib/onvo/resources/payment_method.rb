# frozen_string_literal: true

module Onvo
  # PaymentMethods represent saved or tokenized payment instruments
  # (cards, SINPE Movil, etc.). Pass customer_id at creation time to
  # attach it to a Customer immediately — ONVO has no separate attach step.
  #
  #   pm = Onvo::PaymentMethod.create(type: "card", card: { token: "tok_123" }, customer_id: "cus_123")
  #   Onvo::PaymentMethod.retrieve("pm_123")
  #   Onvo::PaymentMethod.list(customer_id: "cus_123")
  #   Onvo::PaymentMethod.detach("pm_123")
  class PaymentMethod < APIResource
    OBJECT_NAME = "payment_method"

    extend Operations::Create
    extend Operations::Retrieve
    extend Operations::List

    # Detach a PaymentMethod from its Customer.
    def self.detach(id, client: default_client)
      request(:post, "#{resource_url_for(id)}/detach", {}, client: client)
    end
  end
end
