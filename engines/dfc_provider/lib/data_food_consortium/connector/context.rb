# frozen_string_literal: true

# Preload the DFC context.
#
# Similar to: https://github.com/ruby-rdf/json-ld-preloaded/
module DataFoodConsortium
  module Connector
    class Context < JSON::LD::Context
      VERSION_1_8 = JSON.parse <<~JSON
        {
          "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
          "skos" : "http://www.w3.org/2004/02/skos/core#",
          "dfc": "https://github.com/datafoodconsortium/ontology/releases/latest/download/DFC_FullModel.owl#",
          "dc": "http://purl.org/dc/elements/1.1/#",
          "dfc-b": "https://github.com/datafoodconsortium/ontology/releases/latest/download/DFC_BusinessOntology.owl#",
          "dfc-p": "https://github.com/datafoodconsortium/ontology/releases/latest/download/DFC_ProductGlossary.owl#",
          "dfc-t": "https://github.com/datafoodconsortium/ontology/releases/latest/download/DFC_TechnicalOntology.owl#",
          "dfc-m": "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/measures.rdf#",
          "dfc-pt": "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#",
          "dfc-f": "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/facets.rdf#",
          "ontosec": "http://www.semanticweb.org/ontologies/2008/11/OntologySecurity.owl#",
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
          "dfc-b:hasCertification":{ "@type":"@id" },
          "dfc-b:manages":{ "@type":"@id" },
          "dfc-b:offeredThrough":{ "@type":"@id" },
          "dfc-b:hasBrand":{ "@type":"@id" },
          "dfc-b:hasGeographicalOrigin":{ "@type":"@id" },
          "dfc-b:hasClaim":{ "@type":"@id" },
          "dfc-b:hasAllergenDimension":{ "@type":"@id" },
          "dfc-b:hasNutrientDimension":{ "@type":"@id" },
          "dfc-b:hasPhysicalDimension":{ "@type":"@id" },
          "dfc:owner":{ "@type":"@id" },
          "dfc-t:hostedBy":{ "@type":"@id" },
          "dfc-t:hasPivot":{ "@type":"@id" },
          "dfc-t:represent":{ "@type":"@id" }
        }
      JSON

      add_preloaded("http://www.datafoodconsortium.org/") { parse(VERSION_1_8) }
      alias_preloaded(
        "http://static.datafoodconsortium.org/ontologies/context.json",
        "http://www.datafoodconsortium.org/"
      )
    end
  end
end
