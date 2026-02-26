# frozen_string_literal: true

module Onvo
  # Prices define the unit amount and currency for a Product.
  #
  #   Onvo::Price.create(
  #     product_id: "prod_123",
  #     amount: 1500,
  #     currency: "USD",
  #     interval: "month"
  #   )
  #   Onvo::Price.retrieve("price_123")
  #   Onvo::Price.list(product_id: "prod_123")
  class Price < APIResource
    OBJECT_NAME = "price"

    extend Operations::Create
    extend Operations::Retrieve
    extend Operations::List
  end
end
