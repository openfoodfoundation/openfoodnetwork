# frozen_string_literal: true

module DfcProvider
  class SuppliedProduct < DataFoodConsortium::Connector::SuppliedProduct
    attr_accessor :spree_product_id
    attr_accessor :image

    def initialize(semantic_id, spree_product_id: nil, image_url: nil, **properties)
      super(semantic_id, **properties)

      self.spree_product_id = spree_product_id
      self.image = image_url

      registerSemanticProperty("ofn:spree_product_id") do
        self.spree_product_id
      end
      # Temporary solution, will be replaced by "dfc_b:image" in future version of the DFC connector
      registerSemanticProperty("ofn:image") do
        self.image
      end
    end
  end
end
