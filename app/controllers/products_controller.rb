# frozen_string_literal: true

class ProductsController < BaseController
  def index
    @products = product_renderer.products_view

    @variants_in_cart = current_order.line_items.to_h { |li| [li.variant.id, li.quantity] }
    @low_stock_display = distributor.preferred_product_low_stock_display
  end

  def show
    # Most of the shop uses `current_distributor` and relies on the user
    # only being able to look at one shop at a time.
    # But following a link to view a product shouldn't change the current
    # state of your cart. So we are calling it enterprise here.
    # But we still have to fill other used variables later (see below).
    @enterprise = Enterprise.find_by(permalink: params[:enterprise_permalink])
    @product = Spree::Product.find(params[:id])

    @order_cycles = Shop::OrderCyclesList.ready_for_checkout_for(@enterprise, current_customer)

    # TODO: DRY
    @variants_in_cart = current_order(true).line_items.to_h { |li| [li.variant.id, li.quantity] }
    @low_stock_display = @product.variants.first.enterprise.preferred_product_low_stock_display

    # Lots of views and helpers assume this variable:
    @current_distributor = @enterprise
  end

  private

  def product_renderer
    ProductsRenderer.new(
      distributor,
      order_cycle,
      customer,
      search_params,
      inventory_enabled: inventory_enabled?,
      variant_tag_enabled: variant_tag_enabled?
    )
  end

  def distributor
    @distributor ||= current_distributor
  end

  def order_cycle
    OrderCycle.find_by(id: params[:order_cycle_id])
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
