# frozen_string_literal: true

# This class allows orders with eager-loaded adjustment objects to calculate various adjustment
# types without triggering additional queries.
#
# For example; `order.adjustments.shipping.sum(:amount)` would normally trigger a new query
# regardless of whether or not adjustments have been preloaded, as `#shipping` is an adjustment
# scope, eg; `scope :shipping, where(originator_type: 'Spree::ShippingMethod')`.
#
# Here the adjustment scopes are moved to a shared module, and `adjustments.loaded?` is used to
# check if the objects have already been fetched and initialized. If they have, `order.adjustments`
# will be an Array, and we can select the required objects without hitting the database. If not, it
# will fetch the adjustments via their scopes as normal.

class OrderAdjustmentsFetcher
  include AdjustmentScopes

  def initialize(order)
    @order = order
  end

  def admin_and_handling_total
    admin_and_handling_fees.map(&:amount).sum
  end

  def payment_fee
    sum_adjustments "payment_fee"
  end

  def ship_total
    sum_adjustments "shipping"
  end

  private

  attr_reader :order

  def adjustments
    order.all_adjustments
  end

  def adjustments_eager_loaded?
    adjustments.loaded?
  end

  def sum_adjustments(scope)
    collect_adjustments(scope).map(&:amount).sum
  end

  def collect_adjustments(scope)
    if adjustments_eager_loaded?
      adjustment_scope = public_send("#{scope}_scope")

      # Adjustments are already loaded here, this block is using `Array#select`
      adjustments.select do |adjustment|
        match_by_scope(adjustment, adjustment_scope) && match_by_scope(adjustment, eligible_scope)
      end
    else
      adjustments.where(nil).eligible.public_send scope
    end
  end

  def admin_and_handling_fees
    if adjustments_eager_loaded?
      adjustments.select do |adjustment|
        match_by_scope(adjustment, eligible_scope) &&
          adjustment.originator_type == 'EnterpriseFee' &&
          adjustment.adjustable_type != 'Spree::LineItem'
      end
    else
      adjustments.eligible.
        where("originator_type = ? AND adjustable_type != ?", 'EnterpriseFee', 'Spree::LineItem')
    end
  end

  def match_by_scope(adjustment, scope)
    adjustment.public_send(scope.keys.first) == scope.values.first
  end
end
