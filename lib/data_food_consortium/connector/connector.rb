# frozen_string_literal: true

require_relative "importer"

module DataFoodConsortium
  module Connector
    class Connector
      def import(json_string)
        Importer.new.import(json_string)
      end
    end
  end
end
