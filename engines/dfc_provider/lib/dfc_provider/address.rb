# frozen_string_literal: true

# Temporary solution to add `region` to Address, to be removed once the DFC connector supports it

module DfcProvider
  class Address < DataFoodConsortium::Connector::Address
    # @return [String]
    attr_accessor :region

    def initialize(semantic_id, region: "", **properties)
      super(semantic_id, **properties)
      @region = region

      registerSemanticProperty("dfc-b:region", &method("region")).valueSetter = method("region=")
    end
  end
end
