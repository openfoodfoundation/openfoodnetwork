# frozen_string_literal: true

module OrderStockCheck
  include CablecarResponses
  extend ActiveSupport::Concern

  def valid_order_line_items?
    @order.insufficient_stock_lines.empty? &&
      OrderCycles::DistributedVariantsService.new(@order.order_cycle, @order.distributor).
        distributes_order_variants?(@order)
  end

  def handle_insufficient_stock
    @any_out_of_stock = false

    stock_service = Orders::CheckStockService.new(order: @order)
    return if stock_service.sufficient_stock?

    @any_out_of_stock = true
  end

  def check_order_cycle_expiry
    return unless current_order_cycle&.closed?

    Alert.raise_with_record("Notice: order cycle closed during checkout completion", current_order)
    current_order.empty!
    current_order.set_order_cycle! nil

    flash[:info] = I18n.t('order_cycle_closed')
    respond_to do |format|
      format.cable_ready {
        render status: :see_other, cable_ready: cable_car.redirect_to(url: main_app.shop_path)
      }
      format.json { render json: { path: main_app.shop_path }, status: :see_other }
      format.html { redirect_to main_app.shop_path, status: :see_other }
    end
  end
end
