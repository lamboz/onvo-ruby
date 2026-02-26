# frozen_string_literal: true

module Onvo
  module Operations
    module List
      def list(client: default_client, **filters)
        request(:get, resource_url, filters, client: client)
      end
    end
  end
end
