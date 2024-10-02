# frozen_string_literal: true

module Spree
  module Stock
    class Quantifier
      attr_reader :stock_items

      def initialize(variant)
        @variant = variant
        @stock_items = @variant.stock_items
      end

      def total_on_hand
        # Associated stock_items no longer exist if the variant has been soft-deleted. A variant
        # may still be in an active cart after it's deleted, so this will mark it as out of stock.
        return 0 if @variant.deleted?

        stock_items.sum(:count_on_hand)
      end

      def backorderable?
        stock_items.any?(&:backorderable)
      end

      def can_supply?(required)
        total_on_hand >= required || backorderable?
      end
    end
  end
end
