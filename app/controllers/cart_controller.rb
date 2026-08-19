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

      render_cart_streams(order, variant)
    else
      render_cart_error(cart_service.errors.full_messages.to_sentence, order, variant)
    end
  end

  private

  def render_cart_streams(order, variant)
    order.line_items.reload

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: cart_streams(order) + stock_streams(order, variant)
      end
      format.html { redirect_back_or_to(cart_path) }
    end
  end

  def render_cart_error(message, order, variant)
    respond_to do |format|
      format.turbo_stream do
        render status: :unprocessable_entity,
               turbo_stream: cart_streams(order) + [
                 add_to_cart_stream(order, variant),
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

  # When the requested quantity exceeds the available stock, only the
  # available quantity is saved. We then reset the add to cart widget to
  # the saved quantity and notify the customer with the out of stock
  # modal. Widgets are left alone otherwise so pending changes of a fast
  # clicking customer are not reverted.
  def stock_streams(order, variant)
    OpenFoodNetwork::ScopeVariantToHub.new(order.distributor).scope(variant)
    return [] if variant.on_demand

    saved_quantity = order.find_line_item_by_variant(variant)&.quantity || 0
    return [] if saved_quantity >= params.require(:quantity).to_i

    [
      add_to_cart_stream(order, variant),
      turbo_stream.update("out-of-stock-modal",
                          OutOfStockModalComponent.new(id: "out-of-stock", variants: [variant])),
    ]
  end

  def add_to_cart_stream(order, variant)
    quantity = order.find_line_item_by_variant(variant)&.quantity || 0

    turbo_stream.replace(
      "variant-#{variant.id}",
      AddToCartComponent.new(
        variant:, quantity:,
        low_stock_display: !!order.distributor&.preferred_product_low_stock_display
      )
    )
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
