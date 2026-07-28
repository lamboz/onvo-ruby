# frozen_string_literal: true

module Onvo
  # Handles incoming webhook events from Onvo.
  #
  # ONVO does not sign webhook payloads. Each webhook endpoint has a secret
  # (visible in the ONVO Dashboard), and ONVO sends that same secret value
  # verbatim in the `X-Webhook-Secret` header of every request. Verification
  # is a direct (constant-time) comparison against the secret you have on
  # file for that endpoint — there is no HMAC signature or payload signing.
  #
  # Use Webhook.construct_event to verify the header and parse the payload:
  #
  #   payload        = request.body.read
  #   secret_header  = request.env["HTTP_X_WEBHOOK_SECRET"]
  #   webhook_secret = ENV["ONVO_WEBHOOK_SECRET"]
  #
  #   begin
  #     event = Onvo::Webhook.construct_event(payload, secret_header, webhook_secret)
  #   rescue Onvo::SignatureVerificationError => e
  #     # Header missing or didn't match — reject the request
  #   end
  #
  #   case event.type
  #   when "payment-intent.succeeded"       then ...
  #   when "checkout-session.succeeded"     then ...
  #   when "subscription.renewal.succeeded" then ...
  #   end
  module Webhook
    # Verify the webhook secret header, parse the payload, and return an OnvoObject.
    #
    # @param payload [String] raw request body
    # @param secret_header [String] value of the X-Webhook-Secret header
    # @param webhook_secret [String] the endpoint's secret, as configured in the ONVO Dashboard
    # @return [OnvoObject] parsed event
    def self.construct_event(payload, secret_header, webhook_secret)
      Signature.verify_header!(secret_header, webhook_secret)
      data       = JSON.parse(payload)
      normalized = Util.deep_snake_keys(data)
      OnvoObject.construct_from(normalized)
    end

    # Webhook secret verification.
    module Signature
      # Verify the X-Webhook-Secret header against the configured secret.
      #
      # @raise [SignatureVerificationError] on any verification failure
      # @return [nil]
      def self.verify_header!(secret_header, webhook_secret)
        raise SignatureVerificationError, "No webhook secret header present" if blank?(secret_header)
        raise SignatureVerificationError, "No webhook secret configured" if blank?(webhook_secret)
        raise SignatureVerificationError, "Webhook secret mismatch" unless secure_compare?(secret_header,
                                                                                           webhook_secret,)

        nil
      end

      def self.blank?(value)
        value.nil? || value.strip.empty?
      end
      private_class_method :blank?

      # Constant-time string comparison to prevent timing attacks.
      def self.secure_compare?(str_a, str_b)
        return false unless str_a.bytesize == str_b.bytesize

        l = str_a.unpack("C*")
        r = 0
        str_b.each_byte { |byte| r |= byte ^ l.shift }
        r.zero?
      end
      private_class_method :secure_compare?
    end
  end
end
