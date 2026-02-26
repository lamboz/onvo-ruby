# frozen_string_literal: true

module Onvo
  # Products represent goods or services you sell.
  #
  #   Onvo::Product.create(name: "Pro Plan", description: "Full-featured plan")
  #   Onvo::Product.retrieve("prod_123")
  #   Onvo::Product.list
  class Product < APIResource
    OBJECT_NAME = "product"

    extend Operations::Create
    extend Operations::Retrieve
    extend Operations::List
  end
end
