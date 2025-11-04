# frozen_string_literal: true

module OrderStockCheck
  include CablecarResponses
  extend ActiveSupport::Concern

  delegate :sufficient_stock?, to: :check_stock_service

  def valid_order_line_items?
    OrderCycles::DistributedVariantsService.new(@order.order_cycle, @order.distributor).
      distributes_order_variants?(@order)
  end

  def handle_insufficient_stock
    @any_out_of_stock = false

    return if sufficient_stock?

    @any_out_of_stock = true
    @updated_variants = check_stock_service.update_line_items
  end

  def check_order_cycle_expiry(should_empty_order: true)
    return unless current_order_cycle&.closed?

    Alert.raise_with_record("Notice: order cycle closed during checkout completion", current_order)

    handle_closed_order_cycle if should_empty_order

    flash[:info] = build_order_cycle_message(should_empty_order)
    redirect_to_shop_page(should_empty_order)
  end

  private

  def handle_closed_order_cycle
    current_order.empty!
    current_order.assign_order_cycle!(nil)
  end

  def build_order_cycle_message(should_empty_order)
    # If order is not emptied, we assume user will contact support for next steps
    key = should_empty_order ? 'order_cycle_closed' : 'order_cycle_closed_next_steps'
    I18n.t(key, order_number: current_order.number)
  end

  def redirect_to_shop_page(should_empty_order)
    # If order is not emptied, redirect to shops page because shop page empties the order by default
    redirect_url = should_empty_order ? main_app.shop_path : main_app.shops_path

    respond_to do |format|
      format.cable_ready {
        render status: :see_other, cable_ready: cable_car.redirect_to(url: redirect_url)
      }
      format.json { render json: { path: redirect_url }, status: :see_other }
      format.html { redirect_to redirect_url, status: :see_other }
    end
  end

  def check_stock_service
    @check_stock_service ||= Orders::CheckStockService.new(order: @order)
  end
end
