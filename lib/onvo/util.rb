# frozen_string_literal: true

module Onvo
  module Util
    module_function

    def to_camel_case(str)
      parts = str.to_s.split("_")
      parts[0] + parts[1..].map(&:capitalize).join
    end

    def to_snake_case(str)
      str.to_s
         .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
         .gsub(/([a-z\d])([A-Z])/, '\1_\2')
         .downcase
    end

    # Recursively convert all Hash keys to camelCase.
    # Keys inside a "metadata" hash are left unchanged (user-defined).
    def deep_camel_keys(obj, _inside_metadata: false)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), memo|
          key_str = k.to_s
          memo[to_camel_case(key_str)] = if key_str == "metadata"
                                           v
                                         else
                                           deep_camel_keys(v)
                                         end
        end
      when Array
        obj.map { |v| deep_camel_keys(v) }
      else
        obj
      end
    end

    # Recursively convert all Hash keys to snake_case.
    # Keys inside a "metadata" hash are left unchanged (user-defined).
    def deep_snake_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), memo|
          key_str = to_snake_case(k.to_s)
          memo[key_str] = key_str == "metadata" ? v : deep_snake_keys(v)
        end
      when Array
        obj.map { |v| deep_snake_keys(v) }
      else
        obj
      end
    end

    # Flatten nested hashes for query string encoding using bracket notation.
    # E.g. {metadata: {key: "val"}} -> {"metadata[key]" => "val"}
    def encode_parameters(params, prefix = nil)
      params.each_with_object({}) do |(k, v), result|
        key = prefix ? "#{prefix}[#{k}]" : k.to_s
        case v
        when Hash  then result.merge!(encode_parameters(v, key))
        when Array then v.each_with_index { |val, i| result["#{key}[#{i}]"] = val }
        else            result[key] = v
        end
      end
    end
  end
end
