# frozen_string_literal: true

module Api
  module V1
    class BaseSerializer
      include JSONAPI::Serializer

      def self.url_helpers
        Rails.application.routes.url_helpers
      end
    end
  end
end
