# frozen_string_literal: true

# Load the original library first:
require "datafoodconsortium/connector"

# Then our tools for monky-patching:
require_relative "importer"
require_relative "context"
require_relative "skos_parser_element"
require_relative "skos_concept"
require_relative "skos_parser"

module DataFoodConsortium
  module Connector
    class Connector
      def import(json_string_or_io)
        Importer.new.import(json_string_or_io)
      end

      # Monkey patch private method until fixed upstream:
      # https://github.com/datafoodconsortium/connector-ruby/issues/19
      def loadThesaurus(data) # rubocop:disable Naming/MethodName
        # The root element may be an array or the ontology.
        data = data[0] if data.is_a?(Array)
        @parser.parse(data["@graph"])
      end
    end
  end
end
