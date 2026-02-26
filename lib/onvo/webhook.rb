# frozen_string_literal: true

module Onvo
  # Handles incoming webhook events from Onvo.
  #
  # Use Webhook.construct_event to verify the signature and parse the payload:
  #
  #   payload   = request.body.read
  #   sig_header = request.env["HTTP_ONVO_SIGNATURE"]
  #   secret    = ENV["ONVO_WEBHOOK_SECRET"]
  #
  #   begin
  #     event = Onvo::Webhook.construct_event(payload, sig_header, secret)
  #   rescue Onvo::SignatureVerificationError => e
  #     # Invalid signature — reject the request
  #   end
  #
  #   case event.type
  #   when "payment_intent.succeeded" then ...
  #   when "subscription.created"     then ...
  #   end
  module Webhook
    DEFAULT_TOLERANCE = 300 # seconds (5 minutes)

    # Verify the webhook signature, parse the payload, and return an OnvoObject.
    #
    # @param payload [String] raw request body
    # @param sig_header [String] value of the Onvo-Signature header
    # @param secret [String] webhook endpoint's signing secret
    # @param tolerance [Integer, nil] max age in seconds; nil disables the check
    # @return [OnvoObject] parsed event
    def self.construct_event(payload, sig_header, secret, tolerance: DEFAULT_TOLERANCE)
      Signature.verify_header!(payload, sig_header, secret, tolerance: tolerance)
      data       = JSON.parse(payload)
      normalized = Util.deep_snake_keys(data)
      OnvoObject.construct_from(normalized)
    end

    # Webhook signature verification.
    module Signature
      # Verify a webhook signature header.
      #
      # Header format: "t=<unix_timestamp>,v1=<hmac_hex>"
      #
      # @raise [SignatureVerificationError] on any verification failure
      # @return [nil]
      def self.verify_header!(payload, header, secret, tolerance: DEFAULT_TOLERANCE)
        raise SignatureVerificationError, "No signature header present" if header.nil? || header.strip.empty?
        raise SignatureVerificationError, "No webhook secret provided" if secret.nil? || secret.strip.empty?

        parts     = parse_header(header)
        timestamp = parts["t"]
        signature = parts["v1"]

        raise SignatureVerificationError, "Malformed signature header: #{header.inspect}" unless timestamp && signature

        check_timestamp!(timestamp, tolerance)

        expected = compute_signature(timestamp, payload, secret)
        raise SignatureVerificationError, "Signature mismatch" unless secure_compare?(expected, signature)

        nil
      end

      # Compute the expected HMAC-SHA256 signature for a given payload.
      # Exposed as a public method so tests can generate valid signatures.
      def self.compute_signature(timestamp, payload, secret)
        OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{payload}")
      end

      def self.check_timestamp!(timestamp, tolerance)
        return unless tolerance

        age = Time.now.to_i - Integer(timestamp)
        return if age.abs <= tolerance

        raise SignatureVerificationError,
              "Webhook timestamp is too old or too new (#{age}s, tolerance #{tolerance}s)"
      rescue ArgumentError
        raise SignatureVerificationError, "Invalid timestamp value: #{timestamp.inspect}"
      end
      private_class_method :check_timestamp!

      def self.parse_header(header)
        header.split(",").each_with_object({}) do |part, hash|
          k, v = part.split("=", 2)
          hash[k.strip] = v&.strip
        end
      end
      private_class_method :parse_header

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
