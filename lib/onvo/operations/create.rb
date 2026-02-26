# frozen_string_literal: true

module Onvo
  module Operations
    module Create
      def create(client: default_client, **params)
        request(:post, resource_url, params, client: client)
      end
    end
  end
end
