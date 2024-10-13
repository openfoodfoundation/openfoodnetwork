# frozen_string_literal: true

module OrderStockCheck
  extend ActiveSupport::Concern

  def valid_order_line_items?
    @order.insufficient_stock_lines.empty? &&
      OrderCycles::DistributedVariantsService.new(@order.order_cycle, @order.distributor).
        distributes_order_variants?(@order)
  end

  def handle_insufficient_stock
    return if sufficient_stock?

    flash[:error] = Spree.t(:inventory_error_flash_for_insufficient_quantity)
    redirect_to main_app.cart_path
  end

  def check_order_cycle_expiry
    return unless current_order_cycle&.closed?

    Bugsnag.notify("Notice: order cycle closed during checkout completion") do |payload|
      payload.add_metadata :order, current_order
    end
    current_order.empty!
    current_order.set_order_cycle! nil

    flash[:info] = I18n.t('order_cycle_closed')
    redirect_to main_app.shop_path
  end

  private

  def sufficient_stock?
    @sufficient_stock ||= @order.insufficient_stock_lines.blank?
  end
end
