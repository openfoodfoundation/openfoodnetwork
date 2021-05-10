class CartController < BaseController
  before_action :check_authorization

  def populate
    order = current_order(true)

    cart_service = CartService.new(order)

    cart_service.populate(params.slice(:variants, :quantity), true)
    if cart_service.valid?
      order.cap_quantity_at_stock!
      order.recreate_all_fees!

      variant_ids = variant_ids_in(cart_service.variants_h)

      render json: { error: false,
                     stock_levels: VariantsStockLevels.new.call(order, variant_ids) },
             status: :ok
    else
      render json: { error: cart_service.errors.full_messages.join(",") },
             status: :precondition_failed
    end
  end

  private

  def variant_ids_in(variants_h)
    variants_h.map { |v| v[:variant_id].to_i }
  end

  def check_authorization
    session[:access_token] ||= params[:token]
    order = Spree::Order.find_by(number: params[:id]) || current_order

    if order
      authorize! :edit, order, session[:access_token]
    else
      authorize! :create, Spree::Order
    end
  end
end
