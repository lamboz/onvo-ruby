# frozen_string_literal: true

module Onvo
  # Customers represent the end-users of your business.
  #
  #   Onvo::Customer.create(name: "Ana", email: "ana@example.com")
  #   Onvo::Customer.retrieve("cus_123")
  #   Onvo::Customer.update("cus_123", name: "Ana M.")
  #   Onvo::Customer.delete("cus_123")
  #   Onvo::Customer.list(limit: 10, offset: 0)
  class Customer < APIResource
    OBJECT_NAME = "customer"

    extend Operations::Create
    extend Operations::Retrieve
    extend Operations::Update
    extend Operations::Delete
    extend Operations::List
  end
end
