# frozen_string_literal: true

module OrderStockCheck
  extend ActiveSupport::Concern

  def valid_order_line_items?
    @order.insufficient_stock_lines.empty? &&
      OrderCycleDistributedVariants.new(@order.order_cycle, @order.distributor).
        distributes_order_variants?(@order)
  end

  def handle_insufficient_stock
    return if sufficient_stock?

    reset_order_to_cart

    flash[:error] = Spree.t(:inventory_error_flash_for_insufficient_quantity)
    redirect_to main_app.cart_path
  end

  def check_order_cycle_expiry
    if current_order_cycle&.closed?
      Bugsnag.notify("Notice: order cycle closed during checkout completion", order: current_order)
      current_order.empty!
      current_order.set_order_cycle! nil
      flash[:info] = I18n.t('order_cycle_closed')

      redirect_to main_app.shop_path
    end
  end

  private

  def sufficient_stock?
    @sufficient_stock ||= @order.insufficient_stock_lines.blank?
  end

  def reset_order_to_cart
    return if Flipper.enabled? :split_checkout, spree_current_user

    OrderCheckoutRestart.new(@order).call
  end
end
