# frozen_string_literal: true

class ProductsController < BaseController
  include StartsShopping

  def index
    @products = product_renderer.products_view

    @variants_in_cart = variants_in_cart
    @low_stock_display = distributor.preferred_product_low_stock_display
  end

  def show
    # Most of the shop uses `current_distributor` and relies on the user
    # only being able to look at one shop at a time.
    # But following a link to view a product shouldn't change the current
    # state of your cart. So we are calling it enterprise here.
    # But we still have to fill other used variables later (see below).
    @enterprise = Enterprise.find_by!(permalink: params[:enterprise_permalink])
    @product = Spree::Product.find(params[:id])

    @order_cycles = Shop::OrderCyclesList.ready_for_checkout_for(@enterprise, customer)
    @order_cycle = selected_order_cycle

    # The variants on offer depend on the order cycle. Without one, we can only show the
    # product itself and let the shopper choose an order cycle first.
    @product_view = product_view
    @variants_in_cart = variants_in_cart
    @low_stock_display = distributor.preferred_product_low_stock_display

    # Lots of views and helpers assume these variables. The order cycle selector shows
    # the same order cycle that the variants below it come from.
    @current_distributor = @enterprise
    @current_order_cycle = @order_cycle
  end

  # Choosing an order cycle is the shopper saying that they want to shop here, so unlike
  # viewing the page this does change the cart: it points it at this shop and order cycle
  # the way the shopfront does, emptying it when either of them changes.
  def select_order_cycle
    @enterprise = Enterprise.find_by!(permalink: params[:enterprise_permalink])
    chosen = order_cycle_on_offer(@enterprise, params[:order_cycle_id])

    start_shopping(current_order(true), @enterprise, chosen) if chosen

    redirect_to enterprise_product_path(@enterprise, params[:id])
  end

  private

  def product_renderer(args = search_params)
    ProductsRenderer.new(
      distributor,
      order_cycle,
      customer,
      args,
      inventory_enabled: inventory_enabled?,
      variant_tag_enabled: variant_tag_enabled?
    )
  end

  # The product with its variants filtered for this shop and order cycle, or nil when it
  # isn't on offer, for example when it's out of stock or in no order cycle we can see.
  def product_view
    return if order_cycle.nil?

    product_renderer(q: { id_eq: @product.id }, per_page: 1).products_view.first
  end

  # The order cycle the shopper is shopping in at this shop, or the only one on offer.
  # With several to choose from, they select one before seeing any variants.
  def selected_order_cycle
    current = current_order(false)
    if current&.distributor == @enterprise && @order_cycles.include?(current.order_cycle)
      return current.order_cycle
    end

    @order_cycles.first if @order_cycles.one?
  end

  # `show` looks at a product of any shop, not just the one the shopper is shopping at.
  def distributor
    @distributor ||= @enterprise || current_distributor
  end

  def order_cycle
    return @order_cycle if defined?(@order_cycle)

    @order_cycle = OrderCycle.find_by(id: params[:order_cycle_id])
  end

  # A shopper may have a cart at another shop. Those quantities don't apply here.
  def variants_in_cart
    order = current_order(false)
    return {} unless order&.distributor == distributor

    order.line_items.to_h { |line_item| [line_item.variant_id, line_item.quantity] }
  end

  def customer
    spree_current_user&.customer_of(distributor) || nil
  end

  def search_params
    # params.slice :q, :page, :per_page
    # TODO For experimentation purposed we limit to 1 page and 10 products
    { page: 1, per_page: 10 }
  end

  def inventory_enabled?
    OpenFoodNetwork::FeatureToggle.enabled?(:inventory, distributor)
  end

  def variant_tag_enabled?
    OpenFoodNetwork::FeatureToggle.enabled?(:variant_tag, distributor)
  end
end
