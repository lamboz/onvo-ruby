# frozen_string_literal: true

module Onvo
  # Wraps paginated list responses from the API.
  #
  # The API returns lists in this envelope:
  #   { "data": [...], "total": 100, "limit": 10, "offset": 0 }
  #
  # Example:
  #   customers = Onvo::Customer.list(limit: 10)
  #   customers.each { |c| puts c.email }
  #   customers.has_more?   # => true
  class ListObject < OnvoObject
    include Enumerable

    # The array of resource objects on this page.
    def data
      self["data"] || []
    end

    def each(&)
      data.each(&)
    end

    def empty?
      data.empty?
    end

    # Total number of records matching the filter (across all pages).
    def total
      self["total"]
    end

    def limit
      self["limit"]
    end

    def offset
      self["offset"]
    end

    # Returns true if there are more pages beyond the current one.
    # rubocop:disable Naming/PredicatePrefix
    def has_more?
      api_flag = self["has_more"]
      return api_flag if [true, false].include?(api_flag)

      # Fall back to arithmetic when the API provides total/offset/limit
      offset_val = offset.to_i
      limit_val  = limit.to_i
      total_val  = total.to_i
      limit_val.positive? && (offset_val + limit_val) < total_val
    end
    # rubocop:enable Naming/PredicatePrefix
  end
end
