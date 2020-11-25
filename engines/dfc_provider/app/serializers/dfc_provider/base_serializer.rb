# frozen_string_literal: true

# Serializer used to render the DFC Address from an OFN User
# into JSON-LD format based on DFC ontology
module DfcProvider
  class BaseSerializer < ActiveModel::Serializer
    private

    def host
      Rails.application.routes.default_url_options[:host]
    end

    def dfc_provider_routes
      DfcProvider::Engine.routes.url_helpers
    end
  end
end
