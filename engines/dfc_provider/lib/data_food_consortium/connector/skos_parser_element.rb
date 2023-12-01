# frozen_string_literal: true

module DataFoodConsortium
  module Connector
    class SKOSParserElement
      attr_reader :narrower

      def initialize(element)
        @broader = []
        @narrower = []

        if element
          @id = element["@id"]

          if element["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"]
            @type = extractId(element["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"])
          elsif element["@type"]
            @type = extractId(element["@type"])
          else
            @type = "undefined"
          end

          if element["http://www.w3.org/2004/02/skos/core#broader"]
            element["http://www.w3.org/2004/02/skos/core#broader"].each do |broader|
              @broader.push(broader["@id"])
            end
          end

          if element["http://www.w3.org/2004/02/skos/core#narrower"]
            element["http://www.w3.org/2004/02/skos/core#narrower"].each do |narrower|
              @narrower.push(narrower["@id"])
            end
          end
        else
          @id = ""
          @type = ""
        end
      end

      def isConceptScheme?
        @type == "http://www.w3.org/2004/02/skos/core#ConceptScheme"
      end
    end
  end
end
