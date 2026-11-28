# frozen_string_literal: true

class CartController < BaseController
  include StartsShopping

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
  # of the product grid view instead of #populate.
  def update_variant
    order = current_order(true)
    adopt_shop(order)
    variant = Spree::Variant.find(params[:variant_id])
    cart_service = CartService.new(order)

    if cart_service.update_variant(variant.id, params.require(:quantity),
                                   params[:max_quantity])
      capped_items = order.cap_quantity_at_stock!
      order.recreate_all_fees!

      StockSyncJob.sync_linked_catalogs_later(order)

      capped_variants = (cart_service.capped_variants + capped_items.map(&:variant)).uniq(&:id)
      render_cart_streams(order, capped_variants)
    else
      render_cart_error(cart_service.errors.full_messages.to_sentence, order, variant)
    end
  end

  # Adds the cart's items to one of the customer's placed orders, instead of checking out.
  def add_to_order
    cart = current_order(true)
    # Only the customer's own orders. The service checks the rest, e.g. that the shop allows it.
    order = spree_current_user&.orders&.find_by(number: params[:order_number])
    return refuse_adding_to_order if order.nil?

    OrderLocker.lock_order_and_variants(cart) do
      next if reduce_cart_to_stock?(cart)

      service = Orders::AddCartToOrderService.new(cart:, order:)
      if service.call
        flash[:success] = t(".added", number: order.number)
        redirect_to order_path(order)
      elsif service.error == :insufficient_stock
        # An item sold out after the stock check: the cart page lists what's no longer available.
        redirect_to cart_path
      else
        refuse_adding_to_order
      end
    end
  end

  private

  # Like checkout, reduces or removes the items that sold out since they were put in the cart.
  # The cart page then tells the customer what changed. Returns true if anything changed.
  def reduce_cart_to_stock?(cart)
    stock_check = Orders::CheckStockService.new(order: cart)
    return false if stock_check.sufficient_stock?

    session[:out_of_stock_variant_ids] = stock_check.update_line_items.map(&:id)
    redirect_to cart_path
    true
  end

  def refuse_adding_to_order
    flash[:error] = t(".not_added")
    redirect_to cart_path
  end

  def render_cart_streams(order, capped_variants)
    order.line_items.reload

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: cart_streams(order) + stock_streams(order, capped_variants)
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

  # When a requested quantity exceeds the available stock, only the
  # available quantity is saved. A stock change can also affect other
  # items already in the cart. The affected add to cart widgets are reset
  # to the saved quantity and the out of stock modal notifies the
  # customer. Widgets are left alone otherwise so pending changes of a
  # fast clicking customer are not reverted.
  def stock_streams(order, capped_variants)
    return [] if capped_variants.empty?

    scoper = OpenFoodNetwork::ScopeVariantToHub.new(order.distributor)
    capped_variants.each { |capped_variant| scoper.scope(capped_variant) }

    capped_variants.map { |capped_variant| add_to_cart_stream(order, capped_variant) } + [
      turbo_stream.update("out-of-stock-modal",
                          OutOfStockModalComponent.new(id: "out-of-stock",
                                                       variants: capped_variants)),
    ]
  end

  def add_to_cart_stream(order, variant)
    line_item = order.find_line_item_by_variant(variant)
    cart_item = ViewData::CartItem.new(quantity: line_item&.quantity || 0,
                                       max_quantity: line_item&.max_quantity)

    turbo_stream.replace(
      "variant-#{variant.id}",
      AddToCartComponent.new(
        variant:, cart_item:,
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
