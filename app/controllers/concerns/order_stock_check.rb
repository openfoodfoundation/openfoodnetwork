# frozen_string_literal: true

module OrderStockCheck
  extend ActiveSupport::Concern

  def handle_insufficient_stock
    return if sufficient_stock?

    flash[:error] = Spree.t(:inventory_error_flash_for_insufficient_quantity)
    redirect_to main_app.cart_path
  end

  private

  def sufficient_stock?
    @sufficient_stock ||= @order.insufficient_stock_lines.blank?
  end
end
