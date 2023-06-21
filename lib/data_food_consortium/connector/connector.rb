# frozen_string_literal: true

require_relative "importer"

module DataFoodConsortium
  module Connector
    class Connector
      def import(json_string_or_io)
        Importer.new.import(json_string_or_io)
      end
    end
  end
end
