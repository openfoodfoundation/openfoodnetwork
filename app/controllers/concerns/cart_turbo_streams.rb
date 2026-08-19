# frozen_string_literal: true

# Renders the Turbo Stream responses of the Turbo cart in the product
# grid view: the cart sidebar, reset add to cart widgets and the out of
# stock modal.
module CartTurboStreams
  private

  def render_cart_streams(order, variant, capped_variants)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: cart_streams(order) + stock_streams(order, variant, capped_variants)
      end
      format.html { redirect_back_or_to(main_app.cart_path) }
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
        redirect_back_or_to(main_app.cart_path)
      end
    end
  end

  def cart_streams(order)
    [
      turbo_stream.replace("cart-sidebar", CartSidebarComponent.new(order:)),
    ]
  end

  # When the requested quantity exceeds the available stock, only the
  # available quantity is saved. A stock change can also affect other
  # items already in the cart, so we check all capped quantities. The
  # affected add to cart widgets are reset to the saved quantity and the
  # out of stock modal notifies the customer. Widgets are left alone
  # otherwise so pending changes of a fast clicking customer are not
  # reverted.
  def stock_streams(order, variant, capped_variants)
    scoper = OpenFoodNetwork::ScopeVariantToHub.new(order.distributor)
    scoper.scope(variant)

    capped = capped_variants
    capped = [variant] + capped if requested_more_than_saved?(order, variant)
    capped = capped.uniq(&:id)
    return [] if capped.empty?

    capped.each { |capped_variant| scoper.scope(capped_variant) }

    capped.map { |capped_variant| add_to_cart_stream(order, capped_variant) } + [
      turbo_stream.update("out-of-stock-modal",
                          OutOfStockModalComponent.new(id: "out-of-stock", variants: capped)),
    ]
  end

  # The quantity can already be reduced when the variant is added to the
  # cart, which #cap_quantity_at_stock doesn't see.
  def requested_more_than_saved?(order, variant)
    return false if variant.on_demand

    saved_quantity = order.find_line_item_by_variant(variant)&.quantity || 0
    saved_quantity < params.require(:quantity).to_i
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
end
