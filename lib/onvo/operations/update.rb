# frozen_string_literal: true

module Onvo
  module Operations
    module Update
      # ONVO's REST API uses POST (not PATCH) for updates on every resource.
      def update(id, client: default_client, **params)
        request(:post, resource_url_for(id), params, client: client)
      end
    end
  end
end
