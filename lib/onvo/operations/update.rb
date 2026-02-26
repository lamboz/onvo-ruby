# frozen_string_literal: true

module Onvo
  module Operations
    module Update
      def update(id, client: default_client, **params)
        request(:patch, resource_url_for(id), params, client: client)
      end
    end
  end
end
