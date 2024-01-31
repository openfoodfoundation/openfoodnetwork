# frozen_string_literal: true

module DfcProvider
  class SuppliedProduct < DataFoodConsortium::Connector::SuppliedProduct
    attr_accessor :spree_product_id, :image

    def initialize(semantic_id, spree_product_id: nil, image_url: nil, **properties)
      super(semantic_id, **properties)

      self.spree_product_id = spree_product_id
      self.image = image_url

      register_ofn_property("spree_product_id")
      # Temporary solution, will be replaced by "dfc_b:image" in future version of the DFC connector
      register_ofn_property("image")
    end

    def register_ofn_property(name)
      registerSemanticProperty("ofn:#{name}", &method(name))
        .valueSetter = method("#{name}=")
    end
  end
end
