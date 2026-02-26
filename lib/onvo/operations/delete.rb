# frozen_string_literal: true

module Onvo
  module Operations
    module Delete
      def delete(id, client: default_client)
        request(:delete, resource_url_for(id), {}, client: client)
      end
    end
  end
end
