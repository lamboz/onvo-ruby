# frozen_string_literal: true

module Onvo
  module Operations
    module Retrieve
      def retrieve(id, client: default_client)
        request(:get, resource_url_for(id), {}, client: client)
      end
    end
  end
end
