module OpenFoodNetwork
  class ScopeVariantToHub
    def initialize(hub, variant_overrides=nil)
      @hub = hub
      @variant_overrides = variant_overrides || VariantOverride.indexed(@hub)
    end

    def scope(variant)
      variant.send :extend, OpenFoodNetwork::ScopeVariantToHub::ScopeVariantToHub
      variant.instance_variable_set :@hub, @hub
      variant.instance_variable_set :@variant_override, @variant_overrides[variant]
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

      def on_demand
        if @variant_override.andand.on_demand.nil?
          if @variant_override.andand.count_on_hand.present?
            # If we're overriding the stock level of an on_demand variant, show it as not
            # on_demand, so our stock control can take effect.
            false
          else
            super
          end
        else
          @variant_override.andand.on_demand
        end
      end

      def decrement!(attribute, by=1)
        if attribute == :count_on_hand && @variant_override.andand.stock_overridden?
          @variant_override.decrement_stock! by
        else
          super
        end
      end

      def increment!(attribute, by=1)
        if attribute == :count_on_hand && @variant_override.andand.stock_overridden?
          @variant_override.increment_stock! by
        else
          super
        end
      end

      def sku
        @variant_override.andand.sku || super
      end

      def tag_list
        @variant_override.andand.tag_list || []
      end
    end
  end
end
