# frozen_string_literal: true

module Onvo
  # A MobileTransfer is a read-only record of an inbound SINPE Móvil
  # transfer received on your account's "número móvil personalizado" (a
  # single, fixed mobile number assigned to your ONVO account for
  # receiving SINPE Móvil payments).
  #
  # There is no create/retrieve-by-id endpoint for this resource — only a
  # list, at GET /v1/mobile-transfers/list (note the /list suffix; unlike
  # every other resource, the collection endpoint is not the bare
  # "/mobile-transfers" path).
  #
  # ONVO tries to automatically link each inbound transfer to a pending
  # PaymentIntent confirmed with a matching `mobile_number` PaymentMethod
  # (matched by sender identity, not amount). Use this list — filtered by
  # status — as the reconciliation queue for transfers it couldn't match:
  #
  #   Onvo::MobileTransfer.list(status: "charge_not_found,attempt_not_found")
  #
  # Statuses: pending, received, attempt_not_found, charge_not_found,
  # expired, canceled. `payment_intent_id` is nil until ONVO links the
  # transfer to an intent.
  #
  # Requires the customized mobile number to be enabled on your ONVO
  # account — otherwise every call returns 400 ("La cuenta no tiene
  # habilitado el número móvil personalizado").
  class MobileTransfer < APIResource
    OBJECT_NAME = "mobile_transfer"

    # @param filters [Hash] :status, :sinpe_ref_number, :origin_id,
    #   :origin_name, :description, :created_at, :limit, :starting_after,
    #   :ending_before, :sort_order
    def self.list(client: default_client, **filters)
      request(:get, "/mobile-transfers/list", normalize_filters(filters), client: client)
    end

    # ONVO's own query param is the literal "SINPERefNumber" — an
    # all-caps-acronym casing that Util's generic snake<->camel conversion
    # can't derive from an idiomatic Ruby key (:sinpe_ref_number would
    # become "sinpeRefNumber", which the API silently ignores as an unknown
    # filter). Renamed here to the exact wire key before the shared camelize
    # pass runs — a key with no underscores passes through unchanged.
    def self.normalize_filters(filters)
      return filters unless filters.key?(:sinpe_ref_number)

      filters.except(:sinpe_ref_number).merge("SINPERefNumber" => filters[:sinpe_ref_number])
    end
    private_class_method :normalize_filters
  end
end
