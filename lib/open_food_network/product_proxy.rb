module OpenFoodNetwork
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
