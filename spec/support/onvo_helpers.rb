# frozen_string_literal: true

module OnvoHelpers
  TEST_SECRET_KEY = "sk_test_fake_key_for_testing"
  TEST_API_BASE   = "https://api.onvopay.com/v1"

  # Stub an Onvo API request via WebMock.
  #
  # @param method [Symbol]  :get, :post, :patch, :delete
  # @param path [String]    relative path, e.g. "/customers" or "/customers/cus_123"
  # @param status [Integer] HTTP response status (default 200)
  # @param request_body [Hash, nil]  expected request body for POST/PATCH stubs
  # @param response_body [Hash]      response JSON body
  # @return [WebMock::RequestStub]
  def stub_onvo(method, path, status: 200, request_body: nil, response_body: {})
    url  = "#{TEST_API_BASE}#{path}"
    stub = stub_request(method, url)
    stub = stub.with(body: request_body.to_json) if request_body
    stub.to_return(
      status: status,
      body: response_body.to_json,
      headers: { "Content-Type" => "application/json" },
    )
  end

  # Stub a request that raises a network-level timeout.
  def stub_onvo_timeout(method, path)
    stub_request(method, "#{TEST_API_BASE}#{path}").to_timeout
  end

  # Stub a request that raises a connection-refused error.
  def stub_onvo_connection_refused(method, path)
    stub_request(method, "#{TEST_API_BASE}#{path}").to_raise(Errno::ECONNREFUSED)
  end
end

RSpec.configure do |config|
  config.include OnvoHelpers
end
