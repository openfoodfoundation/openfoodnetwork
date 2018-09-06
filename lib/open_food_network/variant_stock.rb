require 'active_support/concern'

# These methods were available in Spree 1, but were removed in Spree 2.
# We would still like to use them. Therefore we use only a single stock location
# (default stock location) and use it to track the `count_on_hand` value that
# was previously a database column on variants.
#
# We may decide to deprecate these methods after we designed the Network feature.
module OpenFoodNetwork
  module VariantStock
    extend ActiveSupport::Concern

    included do
      after_save :save_stock
    end

    def on_hand
      if on_demand
        Float::INFINITY
      else
        total_on_hand
      end
    end

    def count_on_hand
      total_on_hand
    end

    def on_hand=(new_level)
      error = 'Cannot set on_hand value when Spree::Config[:track_inventory_levels] is false'
      raise error unless Spree::Config.track_inventory_levels

      self.count_on_hand = new_level
    end

    def count_on_hand=(new_level)
      raise_error_if_no_stock_item_available
      overwrite_stock_levels new_level
    end

    def on_demand
      stock_items.any?(&:backorderable?)
    end

    def on_demand=(new_value)
      raise_error_if_no_stock_item_available

      # There should be only one at the default stock location.
      stock_items.each do |item|
        item.backorderable = new_value
      end
    end

    private

    def save_stock
      stock_items.each(&:save)
    end

    def raise_error_if_no_stock_item_available
      message = 'You need to save the variant to create a stock item before you can set stock levels.'
      raise message if stock_items.empty?
    end

    # Backwards compatible setting of stock levels in Spree 2.0.
    # It would be better to use `Spree::StockItem.adjust_count_on_hand` which
    # takes a value to add to the current stock level and uses proper locking.
    # But this should work the same as in Spree 1.3.
    def overwrite_stock_levels(new_level)
      stock_items.first.send :count_on_hand=, new_level

      # There shouldn't be any other stock items, because we should have only one
      # stock location. But in case there are, the total should be new_level,
      # so all others need to be zero.
      stock_items[1..-1].each do |item|
        item.send :count_on_hand=, 0
      end
    end
  end
end
