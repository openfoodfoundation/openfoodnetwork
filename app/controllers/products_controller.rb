# frozen_string_literal: true

class ProductsController < BaseController
  def index
    @products = ProductsRenderer.new(
      distributor,
      order_cycle,
      customer,
      search_params,
      inventory_enabled: inventory_enabled?,
      variant_tag_enabled: variant_tag_enabled?
    ).products

    @variants_in_cart = current_order.line_items.to_h { |li| [li.variant.id, li.quantity] }
  end

  private

  def distributor
    current_distributor
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
