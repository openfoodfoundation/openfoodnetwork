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
    attr_accessible :on_hand, :on_demand
    after_update :save_stock
  end

  # Returns the number of items of the variant available in the stock. When
  # allowing on demand, it returns infinite.
  #
  # Spree computes it as the sum of the count_on_hand of all its stock_items.
  #
  # @return [Float|Integer]
  def on_hand
    warn_deprecation(__method__, '#total_on_hand')

    if on_demand
      Float::INFINITY
    else
      total_on_hand
    end
  end

  # Returns the number of items available in the stock for this variant
  #
  # @return [Float|Integer]
  def count_on_hand
    warn_deprecation(__method__, '#total_on_hand')
    total_on_hand
  end

  # Sets the stock level when `track_inventory_levels` config is
  # set. It raises otherwise.
  #
  # @raise [StandardError] when the track_inventory_levels config
  # key is not set.
  def on_hand=(new_level)
    warn_deprecation(__method__, '#total_on_hand')

    error = 'Cannot set on_hand value when Spree::Config[:track_inventory_levels] is false'
    raise error unless Spree::Config.track_inventory_levels

    self.count_on_hand = new_level
  end

  # Sets the stock level. As opposed to #on_hand= it does not check
  # `track_inventory_levels`'s value as it was previously an ActiveModel
  # setter of the database column of the `spree_variants` table. That is why
  # #on_hand= is more widely used in Spree's codebase using #count_on_hand=
  # underneath.
  #
  # So, if #count_on_hand= is used, `track_inventory_levels` won't be taken
  # into account thus dismissing instance's configuration.
  #
  # It does ensure there's a stock item for the variant however. See
  # #raise_error_if_no_stock_item_available for details.
  #
  # @raise [StandardError] when the variant has no stock item yet
  def count_on_hand=(new_level)
    warn_deprecation(__method__, '#total_on_hand')

    raise_error_if_no_stock_item_available
    overwrite_stock_levels(new_level)
  end

  # Checks whether this variant is produced on demand.
  #
  # In Spree 2.0 this attribute is removed in favour of
  # track_inventory_levels only. It was initially introduced in
  # https://github.com/openfoodfoundation/spree/commit/20b5ad9835dca7f41a40ad16c7b45f987eea6dcc
  def on_demand
    warn_deprecation(__method__, 'StockItem#backorderable?')
    stock_item.backorderable?
  end

  # Sets whether the variant can be ordered on demand or not. Note that
  # although this modifies the stock item, it is not persisted in DB. This
  # may be done to fire a single UPDATE statement when changing various
  # variant attributes, for performance reasons.
  #
  # @raise [StandardError] when the variant has no stock item yet
  def on_demand=(new_value)
    warn_deprecation(__method__, 'StockItem#backorderable=')

    raise_error_if_no_stock_item_available

    # There should be only one at the default stock location.
    #
    # This would be better off as `stock_items.first.save` but then, for
    # unknown reasons, it does not pass the test.
    stock_items.each do |item|
      item.backorderable = new_value
    end
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

  # Backwards compatible setting of stock levels in Spree 2.0.
  def overwrite_stock_levels(new_level)
    stock_item.adjust_count_on_hand(new_level - stock_item.count_on_hand)
  end

  # There shouldn't be any other stock items, because we should
  # have only one stock location.
  def stock_item
    stock_items.first
  end

  def warn_deprecation(method_name, new_method_name)
    ActiveSupport::Deprecation.warn(
      "`##{method_name}` is deprecated and will be removed. " \
      "Please use `#{new_method_name}` instead."
    )
  end
end
