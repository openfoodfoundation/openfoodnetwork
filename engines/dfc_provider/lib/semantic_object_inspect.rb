# frozen_string_literal: true

module VirtualAssembly
  module Semantizer
    module SemanticObject
      # Override PP method, which is used in pretty_inspect for rails console and rspec
      def pretty_print_instance_variables
        instance_variables.reject{ |var| var == :@semanticPropertiesMap }
      end
    end
  end
end
