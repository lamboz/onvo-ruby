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
  c.secret_key      = "sk_live_..."
  c.publishable_key = "pk_live_..." # optional — safe to expose to the browser;
                                     # not required for the hosted Checkout Session flow below,
                                     # only for any future client-side/embedded integration
  c.max_retries     = 2             # default: 2 (retries on 429/500/network errors)
  c.logger          = Rails.logger  # optional
end
```

Alternatively, set environment variables:

```bash
ONVO_SECRET_KEY=sk_live_...
ONVO_PUBLISHABLE_KEY=pk_live_...
```

**API endpoint:** `https://api.onvopay.com/v1` — there is no separate sandbox
host. Test vs. live mode comes entirely from which key you use
(`onvo_test_secret_key_...` vs. `onvo_live_secret_key_...`).

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

# Pass customer_id to attach immediately — Onvo has no separate attach step.
pm = Onvo::PaymentMethod.create(type: "card", card: { token: "tok_123" }, customer_id: "cus_123")
Onvo::PaymentMethod.detach("pm_123")

methods = Onvo::PaymentMethod.list(customer_id: "cus_123")
```

### SINPE Móvil

SINPE Móvil ("mobile_number" payment methods) works through the same
PaymentIntent lifecycle as cards — create a PaymentMethod for the payer's
phone + identification, then confirm a PaymentIntent against it:

```ruby
pm = Onvo::PaymentMethod.create(
  type: "mobile_number",
  mobile_number: {
    number:              "+50688880000",
    identification:      "01-1393-1919", # payer's cédula
    identification_type: 0,              # 0 = cédula física — see ONVO docs for other types
  },
)

pi = Onvo::PaymentIntent.create(amount: 15_000_00, currency: "CRC")
pi = Onvo::PaymentIntent.confirm(pi.id, payment_method_id: pm.id)
pi.status # => "requires_action" or similar — the payer still has to actually
          #    send the SINPE transfer from their banking app to your
          #    account's número móvil personalizado
```

ONVO tries to auto-link the payer's real SINPE Móvil transfer to this
PaymentIntent by identity (phone + cédula), not amount, and fires
`payment-intent.succeeded` once it does. When it can't — wrong sender,
no matching pending intent — the transfer shows up in the reconciliation
queue instead:

```ruby
Onvo::MobileTransfer.list(status: "charge_not_found,attempt_not_found")
```

This requires the "número móvil personalizado" feature enabled on your
ONVO account — it isn't on by default.

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
  customer_id:        "cus_123",
  items:               [{ price_id: "price_456", quantity: 1 }],
  trial_period_days:   14,
  payment_behavior:    "allow_incomplete", # create now, charge once confirmed
)

sub = Onvo::Subscription.retrieve(sub.id)
sub = Onvo::Subscription.update(sub.id, metadata: { order_id: "789" })
sub = Onvo::Subscription.update(sub.id, cancel_at_period_end: true)

Onvo::Subscription.confirm(sub.id, payment_method_id: "pm_123")
Onvo::Subscription.cancel(sub.id) # immediate, permanent

Onvo::Subscription.add_item(sub.id, price_id: "price_789", quantity: 1)
Onvo::Subscription.update_item(sub.id, "si_1", quantity: 3)
Onvo::Subscription.remove_item(sub.id, "si_1")

subscriptions = Onvo::Subscription.list(customer_id: "cus_123", status: "active")
```

### Checkout Sessions

Onvo's hosted checkout: create a session, redirect the customer to its `url`,
then trust the `checkout-session.succeeded` webhook (not the redirect) as
confirmation. A line item's `price_id` can point at a recurring price to
start a subscription through checkout.

```ruby
session = Onvo::Checkout::Session.create(
  line_items:     [{ price_id: "price_456", quantity: 1 }],
  customer_email: "ana@example.com",
  redirect_url:   "https://example.com/success",
  cancel_url:     "https://example.com/cancel",
)
session.url    # => "https://checkout.onvopay.com/pay/..."

session = Onvo::Checkout::Session.retrieve(session.id)
Onvo::Checkout::Session.update_customer(session.id, email: "nueva@example.com")
Onvo::Checkout::Session.expire(session.id)

sessions = Onvo::Checkout::Session.list
```

## Webhooks

Onvo doesn't sign webhook payloads — instead it sends the endpoint's own
secret verbatim in the `X-Webhook-Secret` header. Verify it (a direct,
constant-time comparison) and parse the event payload:

```ruby
# Rails example
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload        = request.body.read
    secret_header  = request.env["HTTP_X_WEBHOOK_SECRET"]
    webhook_secret = ENV["ONVO_WEBHOOK_SECRET"]

    begin
      event = Onvo::Webhook.construct_event(payload, secret_header, webhook_secret)
    rescue Onvo::SignatureVerificationError => e
      render json: { error: e.message }, status: :bad_request and return
    end

    case event.type
    when "payment-intent.succeeded"
      pi = event.data
      # fulfil the order
    when "checkout-session.succeeded"
      session = event.data
      # provision access
    when "subscription.renewal.succeeded"
      renewal = event.data
      # extend the billing period
    end

    head :ok
  end
end
```

Webhook endpoints are registered in the Onvo Dashboard, not via the API —
there is no `WebhookEndpoint` resource.

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
