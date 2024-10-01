# frozen_string_literal: true

module DfcProvider
  class SuppliedProduct < DataFoodConsortium::Connector::SuppliedProduct
    attr_accessor :spree_product_id, :spree_product_uri, :image

    def initialize(
      semantic_id, spree_product_id: nil, spree_product_uri: nil,
      image: nil, image_url: nil, **properties
    )
      super(semantic_id, **properties)

      self.spree_product_id = spree_product_id
      self.spree_product_uri = spree_product_uri
      self.image = image || image_url

      # This is now replaced by spree_product_uri, keeping it for backward compatibility
      register_ofn_property("spree_product_id")
      register_ofn_property("spree_product_uri")
      # Temporary solution, will be replaced by "dfc_b:image" in future version of the DFC connector
      register_ofn_property("image")
      registerSemanticProperty("dfc-b:image", &method(:image))
        .valueSetter = method("image=")
    end

    def register_ofn_property(name)
      registerSemanticProperty("ofn:#{name}", &method(name))
        .valueSetter = method("#{name}=")
    end
  end
end
