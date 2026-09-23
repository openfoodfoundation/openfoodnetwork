# frozen_string_literal: true

# Points a shopper's cart at a shop and one of its order cycles, the way opening a
# shopfront does: changing either of them empties the cart.
#
# The shopfront does this for the shopper when they open it. A product page can be their
# first visit to a shop, so it has to do the same when they choose an order cycle or add
# to their cart from there.
module StartsShopping
  extend ActiveSupport::Concern

  private

  # Pages which can't count on the cart being pointed at them already name the shop and
  # order cycle they belong to in their requests. An empty cart adopts them.
  #
  # A cart with something in it stays where it is, so that adding from another shop's
  # page fails on availability instead of quietly throwing that shopping away.
  def adopt_shop(order)
    return if params[:enterprise_permalink].blank? || order.line_items.any?

    enterprise = Enterprise.is_distributor.find_by(permalink: params[:enterprise_permalink])
    order_cycle = order_cycle_on_offer(enterprise, params[:order_cycle_id])
    return if order_cycle.nil?

    start_shopping(order, enterprise, order_cycle)
  end

  # The order cycle of `enterprise` with the given id, or nil when it isn't one this
  # shopper may buy from. Order cycle ids reaching us from a page are never trusted.
  def order_cycle_on_offer(enterprise, order_cycle_id)
    return if enterprise.nil? || order_cycle_id.blank?

    Shop::OrderCyclesList
      .ready_for_checkout_for(enterprise, shopping_customer_of(enterprise))
      .find { |order_cycle| order_cycle.id == order_cycle_id.to_i }
  end

  def start_shopping(order, enterprise, order_cycle)
    # reset_distributor must be called before any call to the customer
    cart_reset = Orders::CartResetService.new(order, enterprise.permalink)
    cart_reset.reset_distributor
    cart_reset.reset_other!(spree_current_user, shopping_customer_of(enterprise))

    order.assign_order_cycle!(order_cycle)
  end

  def shopping_customer_of(enterprise)
    spree_current_user&.customer_of(enterprise)
  end
end
