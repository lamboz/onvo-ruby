# onvo-ruby

Ruby SDK for the [Onvo Pay](https://onvopay.com) payments API.

Modeled after stripe-ruby with zero runtime dependencies — uses only Ruby stdlib (`net/http`, `uri`, `json`, `openssl`).

## Installation

```ruby
gem "onvo-ruby"
```

Or:

```bash
gem install onvo-ruby
```

## Configuration

```ruby
require "onvo"

# Simple setter
Onvo.secret_key = "sk_live_..."

# Block form (recommended)
Onvo.configure do |c|
  c.secret_key  = "sk_live_..."
  c.sandbox     = false        # default: true (points to api.dev.onvopay.com)
  c.max_retries = 2            # default: 2 (retries on 429/500/network errors)
  c.logger      = Rails.logger # optional
end
```

Alternatively, set environment variables:

```bash
ONVO_SECRET_KEY=sk_live_...
ONVO_SANDBOX=false
```

**API endpoints:**
- Sandbox: `https://api.dev.onvopay.com/v1` (default)
- Production: `https://api.onvopay.com/v1`

## Resources

### Customers

```ruby
customer = Onvo::Customer.create(name: "Ana García", email: "ana@example.com")
customer = Onvo::Customer.retrieve("cus_123")
customer = Onvo::Customer.update("cus_123", name: "Ana M. García")
Onvo::Customer.delete("cus_123")

customers = Onvo::Customer.list(limit: 20)
customers.each { |c| puts c.email }
```

### Payment Intents

```ruby
pi = Onvo::PaymentIntent.create(
  amount:      5000,         # in cents
  currency:    "CRC",        # "USD" or "CRC"
  customer_id: "cus_123",
)

pi = Onvo::PaymentIntent.retrieve(pi.id)
Onvo::PaymentIntent.capture(pi.id)
Onvo::PaymentIntent.cancel(pi.id)

intents = Onvo::PaymentIntent.list(customer_id: "cus_123")
```

### Payment Methods

```ruby
pm = Onvo::PaymentMethod.retrieve("pm_123")
pm.card.last4   # => "4242"
pm.card.brand   # => "visa"

Onvo::PaymentMethod.attach("pm_123", customer_id: "cus_123")
Onvo::PaymentMethod.detach("pm_123")

methods = Onvo::PaymentMethod.list(customer_id: "cus_123")
```

### Products

```ruby
product = Onvo::Product.create(name: "Pro Plan", description: "Monthly subscription")
product = Onvo::Product.retrieve("prod_123")
products = Onvo::Product.list
```

### Prices

```ruby
price = Onvo::Price.create(
  product_id:  "prod_123",
  amount:      2000,
  currency:    "USD",
  recurring:   { interval: "month", interval_count: 1 },
)

price = Onvo::Price.retrieve("price_123")
price.recurring.interval  # => "month"
```

### Subscriptions

```ruby
sub = Onvo::Subscription.create(
  customer_id: "cus_123",
  items:       [{ price_id: "price_456", quantity: 1 }],
)

sub = Onvo::Subscription.retrieve(sub.id)
sub = Onvo::Subscription.update(sub.id, metadata: { order_id: "789" })

Onvo::Subscription.cancel(sub.id, at_period_end: true)
Onvo::Subscription.pause(sub.id)
Onvo::Subscription.resume(sub.id)

subscriptions = Onvo::Subscription.list(customer_id: "cus_123", status: "active")
```

### Webhook Endpoints

```ruby
endpoint = Onvo::WebhookEndpoint.create(
  url:            "https://example.com/webhooks/onvo",
  enabled_events: ["payment_intent.succeeded", "subscription.created"],
)

Onvo::WebhookEndpoint.update(endpoint.id, enabled_events: ["*"])
Onvo::WebhookEndpoint.delete(endpoint.id)
endpoints = Onvo::WebhookEndpoint.list
```

## Webhooks

Verify the incoming signature and parse the event payload:

```ruby
# Rails example
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload    = request.body.read
    sig_header = request.env["HTTP_ONVO_SIGNATURE"]
    secret     = ENV["ONVO_WEBHOOK_SECRET"]

    begin
      event = Onvo::Webhook.construct_event(payload, sig_header, secret)
    rescue Onvo::SignatureVerificationError => e
      render json: { error: e.message }, status: :bad_request and return
    end

    case event.type
    when "payment_intent.succeeded"
      pi = event.data
      # fulfil the order
    when "subscription.created"
      sub = event.data
      # provision the subscription
    end

    head :ok
  end
end
```

## Multi-tenant usage

Pass a dedicated client per API key:

```ruby
client = Onvo::Client.new(
  Onvo::Configuration.new.tap { |c| c.secret_key = tenant_secret_key }
)

customer = Onvo::Customer.retrieve("cus_123", client: client)
```

## Error handling

```ruby
begin
  Onvo::Customer.retrieve("cus_nonexistent")
rescue Onvo::NotFoundError => e
  puts "Not found: #{e.message}"
rescue Onvo::AuthenticationError
  puts "Invalid secret key"
rescue Onvo::RateLimitError
  puts "Too many requests — back off and retry"
rescue Onvo::ServerError => e
  puts "Onvo server error (#{e.http_status}): #{e.message}"
rescue Onvo::APIConnectionError => e
  puts "Network error: #{e.message}"
rescue Onvo::OnvoError => e
  puts "API error: #{e.message}"
end
```

**Error hierarchy:**

```
Onvo::OnvoError
  Onvo::ConfigurationError       — missing or invalid configuration
  Onvo::APIConnectionError       — network errors (timeout, refused)
  Onvo::SignatureVerificationError
  Onvo::AuthenticationError      — 401
  Onvo::PermissionError          — 403
  Onvo::InvalidRequestError      — 400
    Onvo::NotFoundError          — 404 (also rescuable as InvalidRequestError)
  Onvo::RateLimitError           — 429
  Onvo::APIError                 — other HTTP errors
    Onvo::ServerError            — 5xx
```

## Response objects

All API responses are wrapped in `Onvo::OnvoObject`, which provides dot-notation access to all fields. Nested hashes are also wrapped. List responses return `Onvo::ListObject`, which is `Enumerable`.

Keys are automatically converted from the API's camelCase to Ruby's snake_case:

```ruby
customer = Onvo::Customer.retrieve("cus_123")
customer.id           # => "cus_123"
customer.created_at   # => "2024-01-15T10:30:00Z"
customer["email"]     # bracket access also works
```

## Development

```bash
bin/setup          # install dependencies
bundle exec rspec  # run tests
bundle exec rubocop
bin/console        # interactive prompt
```

## Contributing

Bug reports and pull requests are welcome at https://github.com/lamboz/onvo-ruby.

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
