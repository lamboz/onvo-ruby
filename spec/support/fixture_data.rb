# frozen_string_literal: true

module FixtureData
  module_function

  def customer_response(overrides = {})
    {
      "id" => "cus_test_abc123",
      "object" => "customer",
      "email" => "test@example.com",
      "name" => "Test Customer",
      "phone" => "+1234567890",
      "created_at" => "2026-01-15T10:30:00Z",
      "metadata" => {},
    }.merge(overrides)
  end

  def payment_intent_response(overrides = {})
    {
      "id" => "pi_test_abc123",
      "object" => "payment_intent",
      "amount" => 1000,
      "currency" => "USD",
      "status" => "requires_payment_method",
      "customer_id" => "cus_test_abc123",
      "created_at" => "2026-01-15T10:30:00Z",
      "metadata" => {},
    }.merge(overrides)
  end

  def subscription_response(overrides = {})
    {
      "id" => "sub_test_abc123",
      "object" => "subscription",
      "customer_id" => "cus_test_abc123",
      "status" => "active",
      "current_period_start" => "2026-01-01T00:00:00Z",
      "current_period_end" => "2026-02-01T00:00:00Z",
      "items" => [],
      "created_at" => "2026-01-01T00:00:00Z",
      "metadata" => {},
    }.merge(overrides)
  end

  def product_response(overrides = {})
    {
      "id" => "prod_test_abc123",
      "object" => "product",
      "name" => "Test Product",
      "description" => "A test product",
      "active" => true,
      "created_at" => "2026-01-15T10:30:00Z",
      "metadata" => {},
    }.merge(overrides)
  end

  def price_response(overrides = {})
    {
      "id" => "price_test_abc123",
      "object" => "price",
      "product_id" => "prod_test_abc123",
      "unit_amount" => 1000,
      "currency" => "USD",
      "recurring" => { "interval" => "month", "interval_count" => 1 },
      "active" => true,
      "created_at" => "2026-01-15T10:30:00Z",
    }.merge(overrides)
  end

  def payment_method_response(overrides = {})
    {
      "id" => "pm_test_abc123",
      "object" => "payment_method",
      "type" => "card",
      "customer_id" => "cus_test_abc123",
      "card" => {
        "brand" => "visa",
        "last4" => "4242",
        "exp_month" => 12,
        "exp_year" => 2028,
      },
      "created_at" => "2026-01-15T10:30:00Z",
    }.merge(overrides)
  end

  def checkout_session_response(overrides = {})
    {
      "id" => "cs_test_abc123",
      "object" => "checkout_session",
      "url" => "https://checkout.onvopay.com/pay/cs_test_abc123",
      "status" => "open",
      "success_url" => "https://example.com/success",
      "cancel_url" => "https://example.com/cancel",
      "line_items" => [],
      "created_at" => "2026-01-15T10:30:00Z",
    }.merge(overrides)
  end

  def list_response(data:, has_more: false, total: nil)
    {
      "data" => data,
      "total" => total || data.size,
      "limit" => 10,
      "offset" => 0,
      "has_more" => has_more,
    }
  end

  def refund_response(overrides = {})
    {
      "id" => "re_test_abc123",
      "object" => "refund",
      "payment_intent_id" => "pi_test_abc123",
      "amount" => 500,
      "currency" => "USD",
      "reason" => "requested_by_customer",
      "status" => "succeeded",
      "created_at" => "2026-01-15T10:30:00Z",
    }.merge(overrides)
  end

  def mobile_transfer_response(overrides = {})
    {
      "id" => "mt_test_abc123",
      "object" => "mobile_transfer",
      "mode" => "test",
      "amount" => 1_500_000,
      "currency" => "CRC",
      "status" => "received",
      "description" => "Pago factura 12345",
      "sinpe_ref_number" => "2025121616183220990502000",
      "origin_id" => "01-1393-1919",
      "origin_name" => "Juan Pérez Rodríguez",
      "destination_phone" => "70196686",
      "authorization_date" => "2026-01-15T14:30:00.000Z",
      "created_at" => "2026-01-15T14:30:05.587Z",
      "payment_intent_id" => "pi_test_abc123",
    }.merge(overrides)
  end

  def deleted_response(id)
    { "id" => id, "deleted" => true }
  end
end

RSpec.configure do |config|
  config.include FixtureData
end
