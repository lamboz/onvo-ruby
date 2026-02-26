# frozen_string_literal: true

module Onvo
  # Base wrapper for API responses.
  #
  # Wraps a Hash of attributes and provides:
  # - Dot-notation access: obj.customer_id
  # - Bracket access: obj["customer_id"]
  # - Recursive wrapping of nested hashes as OnvoObjects
  # - Serialization back to plain Ruby hash
  class OnvoObject
    def initialize(values = {})
      @values = {}
      update_attributes(values)
    end

    # Build an OnvoObject from a plain Hash (typically a parsed API response).
    def self.construct_from(values)
      new(values)
    end

    # Update internal values from a Hash.
    UNBOXED_KEYS = %w[metadata].freeze

    def update_attributes(values)
      values.each do |k, v|
        key = k.to_s
        @values[key] = UNBOXED_KEYS.include?(key) ? v : wrap_value(v)
      end
      self
    end

    def [](key)
      @values[key.to_s]
    end

    def []=(key, value)
      @values[key.to_s] = wrap_value(value)
    end

    def respond_to_missing?(name, include_private = false)
      @values.key?(name.to_s) || super
    end

    def method_missing(name, *args)
      key = name.to_s
      return @values[key] if @values.key?(key)

      super
    end

    # Return a plain Ruby Hash (recursively unwraps nested OnvoObjects).
    def to_h
      @values.transform_values do |v|
        case v
        when OnvoObject then v.to_h
        when Array      then v.map { |e| e.is_a?(OnvoObject) ? e.to_h : e }
        else                 v
        end
      end
    end
    alias to_hash to_h

    def to_json(*)
      to_h.to_json(*)
    end

    def ==(other)
      other.is_a?(OnvoObject) && @values == other.instance_variable_get(:@values)
    end

    def inspect
      id_str = @values["id"] ? " id=#{@values["id"].inspect}" : ""
      "#<#{self.class}#{id_str} #{@values.except("id").inspect}>"
    end

    private

    def wrap_value(value)
      case value
      when Hash  then OnvoObject.construct_from(value)
      when Array then value.map { |v| wrap_value(v) }
      else            value
      end
    end
  end
end
