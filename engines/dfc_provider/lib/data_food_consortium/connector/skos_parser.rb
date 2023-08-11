# frozen_string_literal: true

# Overriding the current implementation to store all parsed concepts for
# lookup later. Otherwise the importer can't associate these.
# This is just a workaround and needs to be solved upstream.
module DataFoodConsortium
  module Connector
    class SKOSParser
      def self.concepts
        @concepts ||= {}
      end

      protected

      def createSKOSConcept(element) # rubocop:disable Naming/MethodName
        concept = DataFoodConsortium::Connector::SKOSConcept.new
        concept.semanticId = element.id
        concept.semanticType = element.type
        self.class.concepts[element.id] = concept
        concept
      end
    end
  end
end
