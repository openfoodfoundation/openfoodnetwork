# frozen_string_literal: true

require 'active_support/concern'

# These methods were available in Spree 1, but were removed in Spree 2.  We
# would still like to use them so that we still give support to the consumers
# of these methods, making the upgrade backward compatible.
#
# Therefore we use only a single stock item per variant, which is associated to
# a single stock location per instance (default stock location) and use it to
# track the `count_on_hand` value that was previously a database column on
# variants. See
# https://github.com/openfoodfoundation/openfoodnetwork/wiki/Spree-Upgrade%3A-Stock-locations
# for details.
#
# These methods are or may become deprecated.
module VariantStock
  extend ActiveSupport::Concern

  included do
    after_update :save_stock
  end

  # Returns the number of items of the variant available.
  # Spree computes total_on_hand as the sum of the count_on_hand of all its stock_items.
  #
  # @return [Float|Integer]
  def on_hand
    total_on_hand
  end

  # Sets the stock level of the variant.
  # This will only work if there is a stock item for the variant.
  #
  # @raise [StandardError] when the variant has no stock item
  def on_hand=(new_level)
    raise_error_if_no_stock_item_available

    overwrite_stock_levels(new_level)
  end

  # Checks whether this variant is produced on demand.
  def on_demand
    # A variant that has not been saved yet or has been soft-deleted doesn't have a stock item
    #   This provides a default value for variant.on_demand
    #     using Spree::StockLocation.backorderable_default
    return Spree::StockLocation.first.backorderable_default if new_record? || deleted?

    # This can be removed unless we have seen this error in Bugsnag recently
    if stock_item.nil?
      Bugsnag.notify(
        RuntimeError.new("Variant #stock_item called, but the stock_item does not exist!"),
        object: as_json
      )
      return Spree::StockLocation.first.backorderable_default
    end

    stock_item.backorderable?
  end

  # Sets whether the variant can be ordered on demand or not. Note that
  # although this modifies the stock item, it is not persisted in DB. This
  # may be done to fire a single UPDATE statement when changing various
  # variant attributes, for performance reasons.
  #
  # @raise [StandardError] when the variant has no stock item yet
  def on_demand=(new_value)
    raise_error_if_no_stock_item_available

    # There should be only one at the default stock location.
    #
    # This would be better off as `stock_items.first.save` but then, for
    # unknown reasons, it does not pass the test.
    stock_items.each do |item|
      item.backorderable = new_value
      item.save
    end
  end

  # Moving Spree::Stock::Quantifier.can_supply? to the variant enables us
  #   to override this behaviour for variant overrides
  # We can have this responsibility here in the variant because there is
  #   only one stock item per variant
  #
  # Here we depend only on variant.total_on_hand and variant.on_demand.
  #   This way, variant_overrides only need to override variant.total_on_hand and variant.on_demand.
  def can_supply?(quantity)
    on_demand || total_on_hand >= quantity
  end

  # Moving Spree::StockLocation.fill_status to the variant enables us
  #   to override this behaviour for variant overrides
  # We can have this responsibility here in the variant because there is
  #   only one stock item per variant
  #
  # Here we depend only on variant.total_on_hand and variant.on_demand.
  #   This way, variant_overrides only need to override variant.total_on_hand and variant.on_demand.
  def fill_status(quantity)
    on_hand = if total_on_hand >= quantity || on_demand
                quantity
              else
                [0, total_on_hand].max
              end

    backordered = 0

    [on_hand, backordered]
  end

  # We can have this responsibility here in the variant because there is
  #   only one stock item per variant
  #
  # This enables us to override this behaviour for variant overrides
  def move(quantity, originator = nil)
    # Don't change variant stock if variant is on_demand or has been deleted
    return if on_demand || deleted_at

    raise_error_if_no_stock_item_available

    # Creates a stock movement: it updates stock_item.count_on_hand and fills backorders
    #
    # This is the original Spree::StockLocation#move,
    #   except that we raise an error if the stock item is missing,
    #   because, unlike Spree, we should always have exactly one stock item per variant.
    stock_item.stock_movements.create!(quantity: quantity, originator: originator)
  end

  private

  # Persists the single stock item associated to this variant. As defined in
  # the top-most comment, as there's a single stock location in the whole
  # database, there can only be a stock item per variant. See StockItem's
  # definition at
  # https://github.com/openfoodfoundation/spree/blob/43950c3689a77a7f493cc6d805a0edccfe75ebc2/core/app/models/spree/stock_item.rb#L3-L4
  # for details.
  def save_stock
    stock_item.save
  end

  def raise_error_if_no_stock_item_available
    message = 'You need to save the variant to create a stock item before you can set stock levels.'
    raise message if stock_items.empty?
  end

  # Overwrites stock_item.count_on_hand
  #
  # Calling stock_item.adjust_count_on_hand will bypass filling backorders
  #   and creating stock movements
  # If that was required we could call self.move
  def overwrite_stock_levels(new_level)
    stock_item.adjust_count_on_hand(new_level.to_i - stock_item.count_on_hand)
  end

  # There shouldn't be any other stock items, because we should
  # have only one stock location.
  def stock_item
    stock_items.first
  end
end
