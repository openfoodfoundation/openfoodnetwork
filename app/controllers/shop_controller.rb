require 'open_food_network/scope_product_to_hub'

class ShopController < BaseController
  layout "darkswarm"
  before_filter :require_distributor_chosen
  before_filter :set_order_cycles

  def show
    redirect_to main_app.enterprise_shop_path(current_distributor)
  end

  def products
    if @products = products_for_shop

      render status: 200,
             json: ActiveModel::ArraySerializer.new(@products,
                                                    each_serializer: Api::ProductSerializer,
                                                    current_order_cycle: current_order_cycle,
                                                    current_distributor: current_distributor,
                                                    variants: variants_for_shop_by_id).to_json

    else
      render json: "", status: 404
    end
  end

  def order_cycle
    if request.post?
      if oc = OrderCycle.with_distributor(@distributor).active.find_by_id(params[:order_cycle_id])
        current_order(true).set_order_cycle! oc
        render partial: "json/order_cycle"
      else
        render status: 404, json: ""
      end
    else
      render partial: "json/order_cycle"
    end
  end

  private

  def products_for_shop
    if current_order_cycle
      current_order_cycle.
        valid_products_distributed_by(current_distributor).
        order(taxon_order).
        each { |p| p.scope_to_hub current_distributor }.
        select { |p| !p.deleted? && p.has_stock_for_distribution?(current_order_cycle, current_distributor) }
    end
  end

  def variants_for_shop_by_id
    # We use the in_stock? method here instead of the in_stock scope because we need to
    # look up the stock as overridden by VariantOverrides, and the scope method is not affected
    # by them.
    variants = Spree::Variant.
               where(is_master: false).
               for_distribution(current_order_cycle, current_distributor).
               each { |v| v.scope_to_hub current_distributor }.
               select(&:in_stock?)

    variants.inject({}) do |vs, v|
      vs[v.product_id] ||= []
      vs[v.product_id] << v
      vs
    end
  end

  def taxon_order
    if current_distributor.preferred_shopfront_taxon_order.present?
      current_distributor
      .preferred_shopfront_taxon_order
      .split(",").map { |id| "primary_taxon_id=#{id} DESC" }
      .join(",") + ", name ASC"
    else
      "name ASC"
    end
  end
end
