# frozen_string_literal: true

# patches :
# - Maikel: Overriding the current implementation to store all parsed concepts for
#           lookup later. Otherwise the importer can't associate these.
#           This is just a workaround and needs to be solved upstream.

# - Gaetan: Improve parsing of SKOS Concept. Will be fixed upstream

require_relative 'skos_helper'

module DataFoodConsortium
  module Connector
    class SKOSInstance
      include DataFoodConsortium::Connector::SKOSHelper

      # Return a list of singelton methods, ie the list of Concept available
      def topConcepts # rubocop:disable Naming/MethodName
        methods(false).sort
      end
    end
  end
end

# rubocop:disable Naming/VariableName
module DataFoodConsortium
  module Connector
    class SKOSParser
      CONCEPT_SCHEMES = ["Facet", "productTypes"].freeze

      def initialize
        @results = DataFoodConsortium::Connector::SKOSInstance.new
        @skosConcepts = {}
        @rootElements = []
        @broaders = {}
        # Flag used to tell the parser to use SkosConcept object when parsing data from
        # Concept Scheme.
        # defined in CONCEPT_SCHEMES
        @useSkosConcept = false
      end

      def parse(data) # rubocop:disable Metrics/CyclomaticComplexity
        init

        data.each do |element|
          current = DataFoodConsortium::Connector::SKOSParserElement.new(element)

          setSkosConceptFlag(current)

          next unless current.isConcept? || current.isCollection?

          if !@skosConcepts.key?(current.id)
            concept = createSKOSConcept(current)
            @skosConcepts[current.id] = concept
          end

          if current.hasBroader
            current.broader.each do |broader_id|
              if !@broaders.key?(broader_id)
                @broaders[broader_id] = []
              end

              @broaders[broader_id].push(current.id)
            end
          # No broader, save the concept to the root
          else
            @rootElements.push(current.id)
          end
        end

        @rootElements.each do |root_element_id|
          setResults(@results, root_element_id)
        end

        @results
      end

      # Maikel's patch
      def self.concepts
        @concepts ||= {}
      end

      protected

      def createSKOSConcept(element) # rubocop:disable Naming/MethodName
        skosConcept = DataFoodConsortium::Connector::SKOSConcept.new(
          element.id,
          broaders: element.broader,
          narrowers: element.narrower,
          prefLabels: element.label
        )
        skosConcept.semanticType = element.type
        # Maikel's patch
        self.class.concepts[element.id] = skosConcept
        skosConcept
      end

      private

      def init
        @results = DataFoodConsortium::Connector::SKOSInstance.new
        @skosConcepts = {}
        @rootElements = []
        @broaders = {}
        @useSkosConcept = false
      end

      def setResults(parent, id) # rubocop:disable Naming/MethodName
        name = getValueWithoutPrefix(id)

        if !parent.hasAttribute(name)
          if @useSkosConcept && @skosConcepts[id]
            parent.addAttribute(name, @skosConcepts[id])
          else
            parent.addAttribute(name, DataFoodConsortium::Connector::SKOSInstance.new)
          end
        end

        # Leaf concepts, stop the process
        if !@broaders.key?(id)
          parent.instance_variable_set("@#{name}", @skosConcepts[id])
          return
        end

        @broaders[id].each do |narrower|
          parentSkosInstance = parent.instance_variable_get("@#{name}")

          setResults(parentSkosInstance, narrower) # recursive call
        end
      end

      def setSkosConceptFlag(current) # rubocop:disable Naming/MethodName
        @useSkosConcept = true if current.isConceptScheme? && matchingConceptSchemes(current)
      end

      def matchingConceptSchemes(current) # rubocop:disable Naming/MethodName
        regex = /#{CONCEPT_SCHEMES.join('|')}/

        current.id =~ regex
      end
    end
  end
end
# rubocop:enable Naming/VariableName
