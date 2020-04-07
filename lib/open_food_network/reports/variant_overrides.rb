# frozen_string_literal: true

module OpenFoodNetwork
  module Reports
    class VariantOverrides
      def initialize(line_items)
        @line_items = line_items
      end

      def indexed
        variant_overrides.each_with_object(hash_of_hashes) do |variant_override, indexed|
          indexed[variant_override.hub_id][variant_override.variant] = variant_override
        end
      end

      private

      attr_reader :line_items

      def variant_overrides
        VariantOverride.joins(:variant)
          .where(spree_variants: { id: line_items.select(:variant_id) })
      end

      def hash_of_hashes
        Hash.new { |h, k| h[k] = {} }
      end
    end
  end
end
