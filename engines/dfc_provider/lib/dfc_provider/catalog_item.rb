# frozen_string_literal: true

# Temporary solution.
module DfcProvider
  class CatalogItem < DataFoodConsortium::Connector::CatalogItem
    attr_accessor :managedBy

    def initialize(semantic_id, managedBy: "", **properties)
      super(semantic_id, **properties)
      @managedBy = managedBy

      registerSemanticProperty("dfc-b:managedBy", &method("managedBy"))
        .valueSetter = method("managedBy=")
    end
  end
end
