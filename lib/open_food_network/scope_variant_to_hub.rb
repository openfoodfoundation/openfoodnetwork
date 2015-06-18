module OpenFoodNetwork
  class ScopeVariantToHub
    def initialize(hub)
      @hub = hub
    end

    def scope(variant)
      variant.send :extend, OpenFoodNetwork::ScopeVariantToHub::ScopeVariantToHub
      variant.instance_variable_set :@hub, @hub
      variant.instance_variable_set :@variant_override, VariantOverride.send(:for, @hub, variant)
    end


    module ScopeVariantToHub
      def price
        @variant_override.andand.price || super
      end

      def price_in(currency)
        Spree::Price.new(amount: price, currency: currency)
      end

      def count_on_hand
        @variant_override.andand.count_on_hand || super
      end

      def decrement!(attribute, by=1)
        if attribute == :count_on_hand && @variant_override.andand.stock_overridden?
          @variant_override.decrement_stock! by
        else
          super
        end
      end
    end

  end
end
