# frozen_string_literal: true

# Serializer used to render the DFC Address from an OFN User
# into JSON-LD format based on DFC ontology
module DfcProvider
  class BaseSerializer < ActiveModel::Serializer
    private

    def dfc_provider_routes
      DfcProvider::Engine.routes.url_helpers
    end
  end
end
