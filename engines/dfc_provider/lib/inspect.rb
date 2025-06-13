# frozen_string_literal: true

module DfcConnectorInspect
  # Override PP method, which is used in pretty_inspect for rails console
  def pretty_print_instance_variables
    instance_variables.reject{ |var| var == :@semanticPropertiesMap }
  end
end

# Include on all connector classes
DataFoodConsortium::Connector.constants.each do |klass|
  DataFoodConsortium::Connector.const_get(klass).class_eval do
    include DfcConnectorInspect
  end
end
