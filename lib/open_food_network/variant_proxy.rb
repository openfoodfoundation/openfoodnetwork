module OpenFoodNetwork
  class VariantProxy
    instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }

    def initialize(variant, hub)
      @variant = variant
      @hub = hub
    end

    def price
      VariantOverride.price_for(@variant, @hub) || @variant.price
    end


    def method_missing(name, *args, &block)
      @variant.send(name, *args, &block)
    end
  end
end
