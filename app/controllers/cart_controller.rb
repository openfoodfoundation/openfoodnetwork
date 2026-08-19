# frozen_string_literal: true

class CartController < BaseController
  include CartTurboStreams

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
    variant = Spree::Variant.find(params[:variant_id])
    cart_service = CartService.new(order)

    if cart_service.update_variant(variant.id, params.require(:quantity),
                                   params[:max_quantity])
      capped_variants = cap_quantity_at_stock(order)
      order.recreate_all_fees!

      StockSyncJob.sync_linked_catalogs_later(order)

      render_cart_streams(order, variant, capped_variants)
    else
      render_cart_error(cart_service.errors.full_messages.to_sentence, order, variant)
    end
  end

  private

  # Caps all quantities at the available stock and returns the variants
  # which had to be reduced, so we can notify the customer.
  def cap_quantity_at_stock(order)
    quantities = order.line_items.reload.to_h { |item| [item.id, item.quantity] }

    order.cap_quantity_at_stock!

    order.line_items.reload.select { |item| item.quantity < quantities[item.id] }.map(&:variant)
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
