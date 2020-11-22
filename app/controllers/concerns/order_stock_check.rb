# frozen_string_literal: true

module OrderStockCheck
  extend ActiveSupport::Concern

  def ensure_sufficient_stock_lines
    return true if @order.insufficient_stock_lines.blank?

    flash[:error] = Spree.t(:inventory_error_flash_for_insufficient_quantity)
    redirect_to main_app.cart_path
  end
end
