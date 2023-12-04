# frozen_string_literal: true

# Patch: Improve parsing of SKOS Concept. Will be fixed upstream
module DataFoodConsortium
  module Connector
    module SKOSHelper
      def addAttribute(name, value) # rubocop:disable Naming/MethodName
        instance_variable_set("@#{name}", value)
        define_singleton_method(name) do
          instance_variable_get("@#{name}")
        end
      end

      def hasAttribute(name) # rubocop:disable Naming/MethodName
        methods.include?(:"#{name}")
      end
    end
  end
end
