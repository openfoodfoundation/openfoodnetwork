require 'open_food_network/variant_proxy'

module OpenFoodNetwork
  # Variants can have several fields overridden on a per-enterprise basis by the
  # VariantOverride model. These overrides can be applied to variants by wrapping their
  # products in this proxy, which wraps the product's variants in VariantProxy.
  class ProductProxy
    instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }

    def initialize(product, hub)
      @product = product
      @hub = hub
    end

    def variants
      @product.variants.map { |v| VariantProxy.new(v, @hub) }
    end

    def method_missing(name, *args, &block)
      @product.send(name, *args, &block)
    end
  end
end
