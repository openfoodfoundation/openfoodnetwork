module OpenFoodNetwork
  class ScopeVariantToHub
    def initialize(hub, variant_overrides = nil)
      @hub = hub
      @variant_overrides = variant_overrides || VariantOverride.indexed(@hub)
    end

    def scope(variant)
      variant.extend(OpenFoodNetwork::ScopeVariantToHub::ScopeVariantToHub)
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

      # Old Spree has the same logic as here and doesn't need this override.
      # But we need this to use VariantOverrides with Spree 2.0.
      def in_stock?
        return true unless Spree::Config[:track_inventory_levels]

        on_demand || (count_on_hand > 0)
      end

      def count_on_hand
        if @variant_override.present? && @variant_override.stock_overridden?
          @variant_override.count_on_hand
        else
          super
        end
      end

      def on_demand
        if @variant_override.present? && !@variant_override.use_producer_stock_settings?
          @variant_override.on_demand
        else
          super
        end
      end

      def decrement!(attribute, by = 1)
        if attribute == :count_on_hand && @variant_override.andand.stock_overridden?
          @variant_override.decrement_stock! by
        else
          super
        end
      end

      def increment!(attribute, by = 1)
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
