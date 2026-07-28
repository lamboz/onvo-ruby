## [Unreleased]

## [0.2.0] - 2026-07-28

Corrections against Onvo's real REST API (`docs.onvopay.com/openapi.yaml`) —
several resources were previously modeled on an assumed Stripe-like shape
that didn't match Onvo's actual endpoints.

### Fixed
- **Breaking:** webhook verification now matches Onvo's real model — a static
  secret sent verbatim in the `X-Webhook-Secret` header, not an HMAC-signed
  `t=...,v1=...` header. `Webhook.construct_event`'s second argument is now
  the raw header value; it's compared directly against your configured
  secret rather than used to verify a signature.
- **Breaking:** `Operations::Update` (used by `.update` on every resource)
  now sends `POST` instead of `PATCH`, matching Onvo's real API.
- **Breaking:** `Subscription.cancel` now sends `DELETE /subscriptions/:id`
  instead of a nonexistent `POST .../cancel`. To cancel at period end, use
  `Subscription.update(id, cancel_at_period_end: true)` instead.
- **Breaking:** removed `Subscription.pause`/`.resume` — these endpoints
  don't exist in Onvo's API.
- **Breaking:** removed `PaymentMethod.attach` — there is no attach
  endpoint; pass `customer_id` to `PaymentMethod.create` instead.
- **Breaking:** removed `WebhookEndpoint` — there is no webhook management
  endpoint in Onvo's API; endpoints are registered in the Onvo Dashboard.

### Added
- `Onvo::Checkout::Session` — create/retrieve/list/confirm/expire, and
  update a session's line item or customer. Onvo's hosted checkout flow.
  A line item's `price_id` can point at a recurring price, so this is also
  the recommended way to start a subscription without touching a raw card.
- `Subscription.confirm` — confirm a subscription created with
  `payment_behavior: "allow_incomplete"`.
- `Subscription.add_item` / `.update_item` / `.remove_item`.
- `Configuration#publishable_key` (+ `ONVO_PUBLISHABLE_KEY` env fallback) — safe
  to expose to the browser, distinct from `secret_key`. Not required for the
  Checkout Session flow above; reserved for any future client-side/embedded
  integration.
- The Refund resource's changelog entry (previously undocumented here despite
  landing in a prior commit).

## [0.1.0] - 2026-02-26

- Initial release
