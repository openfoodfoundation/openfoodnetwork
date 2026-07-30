# frozen_string_literal: true

class CartController < BaseController
  before_action :check_authorization

  def populate
    order = current_order(true)
    cart_service = CartService.new(order)

    if cart_service.populate(params.slice(:variants, :quantity))
      order.cap_quantity_at_stock!
      order.recreate_all_fees!

      StockSyncJob.sync_linked_catalogs_later(order)

      render json: { error: false, stock_levels: stock_levels(order) }, status: :ok
    else
      render json: { error: cart_service.errors.full_messages.join(",") },
             status: :precondition_failed
    end
  end

  # Sets the quantity of a single variant in the cart and responds with
  # Turbo Streams re-rendering the cart sidebar. Used by the Turbo cart
  # (turbo_cart feature) instead of #populate.
  def update_variant
    order = current_order(true)
    variant = Spree::Variant.find(params[:variant_id])
    cart_service = CartService.new(order)

    if cart_service.update_variant(variant.id, params.require(:quantity),
                                   params[:max_quantity])
      order.cap_quantity_at_stock!
      order.recreate_all_fees!

      StockSyncJob.sync_linked_catalogs_later(order)

      render_cart_streams(order)
    else
      render_cart_error(cart_service.errors.full_messages.to_sentence, order)
    end
  end

  private

  def render_cart_streams(order)
    order.line_items.reload

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: cart_streams(order)
      end
      format.html { redirect_back_or_to(cart_path) }
    end
  end

  def render_cart_error(message, order)
    respond_to do |format|
      format.turbo_stream do
        render status: :unprocessable_entity,
               turbo_stream: cart_streams(order) + [
                 turbo_stream.replace("flashes", partial: "shared/flashes",
                                                 locals: { flashes: { error: message } })
               ]
      end
      format.html do
        flash[:error] = message
        redirect_back_or_to(cart_path)
      end
    end
  end

  def cart_streams(order)
    [
      turbo_stream.replace("cart-sidebar", CartSidebarComponent.new(order:)),
    ]
  end

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
