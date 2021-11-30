# frozen_string_literal: true

# Serializer used to render the DFC Address from an OFN User
# into JSON-LD format based on DFC ontology
module DfcProvider
  class BaseSerializer < ActiveModel::Serializer
    include DfcProvider::Engine.routes.url_helpers

    def context
      {
        'dfc' => 'https://static.datafoodconsortium.org/ontologies/DFC_FullModel.owl#',
        '@base' => "#{api_v0_dfc_provider_base_url}/"
      }
    end
  end
end
