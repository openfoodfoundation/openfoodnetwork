# frozen_string_literal: true

module DfcConnectorInspect
  def inspect
    # Show all other instance variables, which are a summary of the semanticPropertiesMap
    "#<#{self.class.name} #{instance_values.except('semanticPropertiesMap')}>"
  end
end

# Include custom inspect on all connector classes
DataFoodConsortium::Connector.constants.each do |klass|
  DataFoodConsortium::Connector.const_get(klass).class_eval do
    include DfcConnectorInspect
  end
end
