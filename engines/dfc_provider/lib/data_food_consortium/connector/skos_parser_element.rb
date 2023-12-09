# frozen_string_literal: true

# Patch: Improve parsing of SKOS Concept. Will be fixed upstream
module DataFoodConsortium
  module Connector
    class SKOSParserElement
      attr_reader :narrower, :label

      def initialize(element) # rubocop:disable Metrics/CyclomaticComplexity
        @broader = []
        @narrower = []
        @label = {}

        if element
          @id = element["@id"]

          @type = if element["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"]
                    extractId(element["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"])
                  elsif element["@type"]
                    extractId(element["@type"])
                  else
                    "undefined"
                  end

          element["http://www.w3.org/2004/02/skos/core#broader"]&.each do |broader|
            @broader.push(broader["@id"])
          end

          element["http://www.w3.org/2004/02/skos/core#narrower"]&.each do |narrower|
            @narrower.push(narrower["@id"])
          end

          element["http://www.w3.org/2004/02/skos/core#prefLabel"]&.each do |label|
            @label[label["@language"].to_sym] = label["@value"]
          end
        else
          @id = ""
          @type = ""
        end
      end

      def isConceptScheme? # rubocop:disable Naming/MethodName
        @type == "http://www.w3.org/2004/02/skos/core#ConceptScheme"
      end
    end
  end
end
