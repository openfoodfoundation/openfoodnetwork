# frozen_string_literal: true

# Serializer used to render the DFC Person from an OFN User
# into JSON-LD format based on DFC ontology
module DfcProvider
  class PersonSerializer < ActiveModel::Serializer
    include RouteHelper

    attribute :context, key: '@context'
    attribute :id, key: '@id'
    attribute :type, key: '@type'
    attribute :family_name, key: 'dfc-b:familyName'
    attribute :first_name, key: 'df-bc:firstName'
    has_one :address,
            key: 'dfc-b:hasAddress',
            serializer: DfcProvider::AddressSerializer
    has_many :affiliates,
             key: 'dfc-b:affiliates',
             serializer: DfcProvider::EnterpriseSerializer

    # Context should be provided inside the controller,
    # but AMS doesn't not supported `meta` and `meta_key` with `root` to nil...
    def context
      {
        'dfc-b' => 'http://static.datafoodconsortium.org/ontologies/dfc_FullModel.owl#',
        'dfc-p' => 'http://static.datafoodconsortium.org/ontologies/DFC_ProductOntology.owl#',
        'dfc-u' => 'http://static.datafoodconsortium.org/data/units.rdf#',
        'dfc-pt' => 'http://static.datafoodconsortium.org/data/types.rdf#',
        'dfc-p:hasUnit' => { '@type' => '@id' },
        'dfc-p:hasType' => { '@type' => '@id' },
        'dfc-b:references' => { '@type' => '@id' },
        'dfc-b:offeredThroug' => { '@type' => '@id' },
        'dfc-b:offeredTo' => { '@type' => '@id' },
        '@base' => "#{root_url}api/dfc_provider"
      }
    end

    def id
      dfc_provider_routes.api_dfc_provider_person_url(
        id: object.id,
        host: host
      )
    end

    def type
      'dfc-b:Person'
    end

    def family_name; end

    def first_name; end

    def address; end

    def affiliates
      object.enterprises
    end
  end
end
