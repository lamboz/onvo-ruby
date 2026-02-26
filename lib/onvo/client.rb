# frozen_string_literal: true

module Onvo
  # HTTP transport layer. Handles authentication, request building,
  # response parsing, error mapping, and retries.
  #
  # The default client is lazily created from the global configuration:
  #   Onvo.default_client
  #
  # For multi-tenant scenarios, instantiate a dedicated client:
  #   client = Onvo::Client.new(Onvo::Configuration.new.tap { |c| c.secret_key = "..." })
  #   Onvo::Customer.retrieve("cus_123", client: client)
  class Client
    # HTTP status codes that are retried (transient errors).
    RETRYABLE_STATUS = [429, 500, 502, 503, 504].freeze

    # Retryable network exceptions.
    RETRYABLE_EXCEPTIONS = [
      Net::OpenTimeout,
      Net::ReadTimeout,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      SocketError,
    ].freeze

    def initialize(config = Onvo.configuration)
      @config = config
      @config.validate!
    end

    def get(path, params = {})
      execute_request(:get, path, params: params)
    end

    def post(path, body = {})
      execute_request(:post, path, body: body)
    end

    def patch(path, body = {})
      execute_request(:patch, path, body: body)
    end

    def delete(path, params = {})
      execute_request(:delete, path, params: params)
    end

    HTTP_METHODS = {
      get: Net::HTTP::Get,
      post: Net::HTTP::Post,
      patch: Net::HTTP::Patch,
      delete: Net::HTTP::Delete,
    }.freeze
    private_constant :HTTP_METHODS

    private

    def execute_request(method, path, params: {}, body: nil)
      attempts = 0
      begin
        attempts += 1
        response = perform_request(method, path, params, body)
        parse_response(response)
      rescue *RETRYABLE_EXCEPTIONS => e
        retry if attempts <= @config.max_retries
        raise APIConnectionError, "Network error: #{e.message}"
      rescue RateLimitError, ServerError
        retry if attempts <= @config.max_retries
        raise
      end
    end

    def perform_request(method, path, params, body)
      uri  = build_uri(path, params)
      http = build_http(uri)
      req  = build_request(method, uri, body)
      log_request(method, uri, body)
      resp = http.request(req)
      log_response(resp)
      resp
    end

    def build_uri(path, params)
      uri = URI.parse("#{@config.api_base}#{path}")
      if params.is_a?(Hash) && !params.empty?
        camel_params = Util.deep_camel_keys(Util.encode_parameters(params))
        uri.query = URI.encode_www_form(camel_params)
      end
      uri
    end

    def build_http(uri)
      http              = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl      = uri.scheme == "https"
      http.open_timeout = @config.open_timeout
      http.read_timeout = @config.read_timeout
      http
    end

    def build_request(method, uri, body)
      req = HTTP_METHODS.fetch(method).new(uri.request_uri)
      req["Authorization"] = "Bearer #{@config.secret_key}"
      req["Content-Type"]  = "application/json"
      req["Accept"]        = "application/json"
      req["User-Agent"]    = "onvo-ruby/#{Onvo::VERSION} Ruby/#{RUBY_VERSION}"
      req.body = JSON.generate(Util.deep_camel_keys(body)) if body && !body.empty?
      req
    end

    def parse_response(resp)
      status = resp.code.to_i
      body   = resp.body.to_s

      raise APIError.from_response(status, body) unless status >= 200 && status < 300

      return nil if body.empty?

      json       = JSON.parse(body)
      normalized = Util.deep_snake_keys(json)

      if normalized.is_a?(Hash) && normalized.key?("data") && normalized["data"].is_a?(Array)
        ListObject.construct_from(normalized)
      else
        OnvoObject.construct_from(normalized)
      end
    end

    def log_request(method, uri, body)
      return unless @config.logger

      @config.logger.debug("[onvo] #{method.upcase} #{uri} #{body.inspect}")
    end

    def log_response(resp)
      return unless @config.logger

      @config.logger.debug("[onvo] #{resp.code} #{resp.body}")
    end
  end
end
