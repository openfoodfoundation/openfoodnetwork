# frozen_string_literal: true

class CartController < BaseController
  before_action :check_authorization

  def populate
    order = current_order(true)
    cart_service = CartService.new(order)

    if cart_service.populate(params.slice(:variants, :quantity))
      order.cap_quantity_at_stock!
      order.recreate_all_fees!

      render json: { error: false, stock_levels: stock_levels(order) }, status: :ok
    else
      render json: { error: cart_service.errors.full_messages.join(",") },
             status: :precondition_failed
    end
  end

  private

  def stock_levels(order)
    variants_in_cart = order.line_items.pluck(:variant_id)
    variants_in_request = raw_params[:variants]&.map(&:first) || []

    VariantsStockLevels.new.call(order, (variants_in_cart + variants_in_request).uniq)
  end

  def check_authorization
    session[:access_token] ||= params[:order_token]
    order = Spree::Order.find_by(number: params[:id]) || current_order

    if order
      authorize! :edit, order, session[:access_token]
    else
      authorize! :create, Spree::Order
    end
  end
end
