# frozen_string_literal: true

module DfcProvider
  class SuppliedProduct < DataFoodConsortium::Connector::SuppliedProduct
    attr_accessor :spree_product_id

    def initialize(semantic_id, spree_product_id: nil, **properties)
      super(semantic_id, **properties)

      self.spree_product_id = spree_product_id

      registerSemanticProperty("ofn:spree_product_id") do
        self.spree_product_id
      end
    end
  end
end
