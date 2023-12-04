# frozen_string_literal: true

require_relative 'skos_helper'

module DataFoodConsortium
  module Connector
    class SKOSInstance
      include DataFoodConsortium::Connector::SKOSHelper

      # Return a list of singelton methods, ie the list of Concept available
      def topConcepts
        self.methods(false).sort
      end
    end
  end
end

# Overriding the current implementation to store all parsed concepts for
# lookup later. Otherwise the importer can't associate these.
# This is just a workaround and needs to be solved upstream.
module DataFoodConsortium
  module Connector
    class SKOSParser
      CONCEPT_SCHEMES = ["Facet", "productTypes"].freeze

      def initialize
        @results = DataFoodConsortium::Connector::SKOSInstance.new
        @skosConcepts = {}
        @rootElements = []
        @broaders = {}
        # Flag used to tell the parser to use SkosConcept object when parsing data from Concept Scheme
        # defined in CONCEPT_SCHEMES
        @useSkosConcept = false
      end

      def parse(data)
        init

        data.each do |element|
          current = DataFoodConsortium::Connector::SKOSParserElement.new(element)

          setSkosConceptFlag(current)

          if current.isConcept? || current.isCollection?
            if !@skosConcepts.has_key?(current.id)
              concept = createSKOSConcept(current)
              @skosConcepts[current.id] = concept
            end

            if current.hasBroader
              current.broader.each do |broaderId|
                if !@broaders.has_key?(broaderId)
                  @broaders[broaderId] = []
                end

                @broaders[broaderId].push(current.id)
              end
            # No broader, save the concept to the root
            else
              @rootElements.push(current.id)
            end
          end
        end

        @rootElements.each do |rootElementId|
          setResults(@results, rootElementId)
        end

        @results
      end

      # TODO check if this is still needed
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
        # TODO check if this is still needed
        # original patch by Maikel
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

      def setResults(parent, id)
        name = getValueWithoutPrefix(id)

        if !parent.hasAttribute(name)
          if @useSkosConcept && !@skosConcepts[id].nil?
            parent.addAttribute(name, @skosConcepts[id])
          else
            parent.addAttribute(name, DataFoodConsortium::Connector::SKOSInstance.new)
          end
        end

        # Leaf concepts, stop the process
        if !@broaders.has_key?(id)
          parent.instance_variable_set("@#{name}", @skosConcepts[id])
          return
        end

        @broaders[id].each do |narrower|
          parentSkosInstance = parent.instance_variable_get("@#{name}")

          setResults(parentSkosInstance, narrower) # recursive call
        end
      end

      def setSkosConceptFlag(current)
        @useSkosConcept = true if current.isConceptScheme? && matchingConceptSchemes(current)
      end

      def matchingConceptSchemes(current)
        regex = /#{CONCEPT_SCHEMES.join("|")}/

        current.id =~ regex
      end
    end
  end
end
