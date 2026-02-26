# frozen_string_literal: true

require_relative "lib/onvo/version"

Gem::Specification.new do |spec|
  spec.name    = "onvo-ruby"
  spec.version = Onvo::VERSION
  spec.authors = ["Pablo Cordero"]
  spec.email   = ["pablo@lamboz.com"]

  spec.summary     = "Ruby SDK for the Onvo payments API"
  spec.description = "A lightweight Ruby client for the Onvo Pay API (https://onvopay.com). " \
                     "Supports customers, products, prices, payment intents, payment methods, " \
                     "subscriptions, and webhook signature verification. Zero runtime dependencies."
  spec.homepage    = "https://github.com/lamboz/onvo-ruby"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  # Zero runtime dependencies — uses only Ruby stdlib:
  # net/http, uri, json, openssl
end
