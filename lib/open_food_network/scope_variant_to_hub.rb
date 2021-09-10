# frozen_string_literal: true

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
        @variant_override&.price || super
      end

      def price_in(currency)
        Spree::Price.new(amount: price, currency: currency)
      end

      # Uses variant_override.count_on_hand instead of Stock::Quantifier.stock_items.count_on_hand
      def total_on_hand
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

      # If it is an variant override with a count_on_hand value:
      #   - updates variant_override.count_on_hand
      #   - does not create stock_movement
      #   - does not update stock_item.count_on_hand
      # If it is a variant override with on_demand:
      #   - don't change stock or call super (super would change the variant's stock)
      def move(quantity, originator = nil)
        return if @variant_override&.on_demand

        if @variant_override&.stock_overridden?
          @variant_override.move_stock! quantity
        else
          super
        end
      end

      def sku
        @variant_override&.sku || super
      end

      def tag_list
        @variant_override&.tag_list || []
      end
    end
  end
end
