# frozen_string_literal: true

module Onvo
  # Base error class for all Onvo SDK errors.
  class OnvoError < StandardError
    attr_reader :http_status, :http_body, :json_body, :code

    def initialize(message = nil, http_status: nil, http_body: nil, json_body: nil, code: nil)
      @http_status = http_status
      @http_body   = http_body
      @json_body   = json_body
      @code        = code
      super(message)
    end
  end

  # Raised when the SDK is misconfigured (e.g. missing secret_key).
  class ConfigurationError < OnvoError; end

  # Raised when a network-level error occurs (timeout, connection refused).
  class APIConnectionError < OnvoError; end

  # Raised when webhook signature verification fails.
  class SignatureVerificationError < OnvoError; end

  # Raised for API-level errors. Subclasses cover specific HTTP status codes.
  class APIError < OnvoError
    # Map an HTTP status code + raw body to the appropriate error subclass.
    def self.from_response(http_status, body)
      json = begin
        JSON.parse(body)
      rescue StandardError
        {}
      end

      message = json.dig("error", "message") || json["message"] || json["error"] || body
      code    = json.dig("error", "code") || json["code"]

      klass = case http_status
              when 400 then InvalidRequestError
              when 401 then AuthenticationError
              when 403 then PermissionError
              when 404 then NotFoundError
              when 429 then RateLimitError
              when 500..599 then ServerError
              else APIError
              end

      klass.new(message, http_status: http_status, http_body: body, json_body: json, code: code)
    end
  end

  # 401 — Invalid or missing API key.
  class AuthenticationError < OnvoError; end

  # 400 — Invalid request parameters.
  class InvalidRequestError < OnvoError; end

  # 403 — Insufficient permissions.
  class PermissionError < OnvoError; end

  # 404 — Resource not found. Subclass of InvalidRequestError so callers can
  # rescue InvalidRequestError and catch 404s too, matching Stripe's behaviour.
  class NotFoundError < InvalidRequestError; end

  # 429 — Rate limit exceeded.
  class RateLimitError < OnvoError; end

  # 500-599 — Server-side error.
  class ServerError < APIError; end
end
