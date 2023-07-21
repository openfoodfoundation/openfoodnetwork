# frozen_string_literal: true

# Our interface to the DFC Connector library.
module DfcIo
  CONTEXT = JSON.parse <<~JSON
    {
      "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
      "skos" : "http://www.w3.org/2004/02/skos/core#",
      "dfc": "http://static.datafoodconsortium.org/ontologies/DFC_FullModel.owl#",
      "dc": "http://purl.org/dc/elements/1.1/#",
      "dfc-b": "http://static.datafoodconsortium.org/ontologies/DFC_BusinessOntology.owl#",
      "dfc-p": "http://static.datafoodconsortium.org/ontologies/DFC_ProductOntology.owl#",
      "dfc-t": "http://static.datafoodconsortium.org/ontologies/DFC_TechnicalOntology.owl#",
      "dfc-m": "http://static.datafoodconsortium.org/data/measures.rdf#",
      "dfc-pt": "http://static.datafoodconsortium.org/data/productTypes.rdf#",
      "dfc-f": "http://static.datafoodconsortium.org/data/facets.rdf#",
      "dfc-p:hasUnit":{ "@type":"@id" },
      "dfc-b:hasUnit":{ "@type":"@id" },
      "dfc-b:hasQuantity":{ "@type":"@id" },
      "dfc-p:hasType":{ "@type":"@id" },
      "dfc-b:hasType":{ "@type":"@id" },
      "dfc-b:references":{ "@type":"@id" },
      "dfc-b:referencedBy":{ "@type":"@id" },
      "dfc-b:offeres":{ "@type":"@id" },
      "dfc-b:supplies":{ "@type":"@id" },
      "dfc-b:defines":{ "@type":"@id" },
      "dfc-b:affiliates":{ "@type":"@id" },
      "dfc-b:hasQuantity":{ "@type":"@id" },
      "dfc-b:manages":{ "@type":"@id" },
      "dfc-b:offeredThrough":{ "@type":"@id" },
      "dfc-b:hasBrand":{ "@type":"@id" },
      "dfc-b:hasGeographicalOrigin":{ "@type":"@id" },
      "dfc-b:hasClaim":{ "@type":"@id" },
      "dfc-b:hasAllergenDimension":{ "@type":"@id" },
      "dfc-b:hasNutrimentDimension":{ "@type":"@id" },
      "dfc-b:hasPhysicalDimension":{ "@type":"@id" },
      "dfc:owner":{ "@type":"@id" },
      "dfc-t:hostedBy":{ "@type":"@id" },
      "dfc-t:hasPivot":{ "@type":"@id" },
      "dfc-t:represent":{ "@type":"@id" }
    }
  JSON

  # Serialise DFC Connector subjects as JSON-LD string.
  #
  # This is a re-implementation of the Connector.export to provide our own context.
  def self.export(*subjects)
    return "" if subjects.empty?

    serializer = VirtualAssembly::Semantizer::HashSerializer.new(CONTEXT)

    hashes = subjects.map do |subject|
      # JSON::LD needs a context on every input using prefixes.
      subject.serialize(serializer).merge("@context" => CONTEXT)
    end

    json_ld = JSON::LD::API.compact(hashes, CONTEXT)
    JSON.generate(json_ld)
  end
end
