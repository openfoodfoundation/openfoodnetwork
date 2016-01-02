require 'open_food_network/scope_product_to_hub'

class ShopController < BaseController
  layout 'darkswarm'
  before_action :require_distributor_chosen
  before_action :set_order_cycles

  def show
    redirect_to main_app.enterprise_shop_path(current_distributor)
  end

  def products
    if @products = products_for_shop

      enterprise_fee_calculator = OpenFoodNetwork::EnterpriseFeeCalculator.new current_distributor, current_order_cycle

      render status: 200,
             json: ActiveModel::ArraySerializer.new(@products,
                                                    each_serializer: Api::ProductSerializer,
                                                    current_order_cycle: current_order_cycle,
                                                    current_distributor: current_distributor,
                                                    variants: variants_for_shop_by_id,
                                                    master_variants: master_variants_for_shop_by_id,
                                                    enterprise_fee_calculator: enterprise_fee_calculator
                                                   ).to_json

    else
      render json: '', status: 404
    end
  end

  def order_cycle
    if request.post?
      if oc = OrderCycle.with_distributor(@distributor).active.find_by_id(params[:order_cycle_id])
        current_order(true).set_order_cycle! oc
        render partial: 'json/order_cycle'
      else
        render status: 404, json: ''
      end
    else
      render partial: 'json/order_cycle'
    end
  end

  private

  def products_for_shop
    if current_order_cycle
      scoper = OpenFoodNetwork::ScopeProductToHub.new(current_distributor)

      current_order_cycle
        .valid_products_distributed_by(current_distributor)
        .order(taxon_order)
        .each { |p| scoper.scope(p) }
        .select { |p| !p.deleted? && p.has_stock_for_distribution?(current_order_cycle, current_distributor) }
    end
  end

  def taxon_order
    if current_distributor.preferred_shopfront_taxon_order.present?
      current_distributor
        .preferred_shopfront_taxon_order
        .split(',').map { |id| "primary_taxon_id=#{id} DESC" }
        .join(',') + ', name ASC'
    else
      'name ASC'
    end
  end

  def all_variants_for_shop
    # We use the in_stock? method here instead of the in_stock scope because we need to
    # look up the stock as overridden by VariantOverrides, and the scope method is not affected
    # by them.
    scoper = OpenFoodNetwork::ScopeVariantToHub.new(current_distributor)
    Spree::Variant
      .for_distribution(current_order_cycle, current_distributor)
      .each { |v| scoper.scope(v) }
      .select(&:in_stock?)
  end

  def variants_for_shop_by_id
    index_by_product_id all_variants_for_shop.reject(&:is_master)
  end

  def master_variants_for_shop_by_id
    index_by_product_id all_variants_for_shop.select(&:is_master)
  end

  def index_by_product_id(variants)
    variants.inject({}) do |vs, v|
      vs[v.product_id] ||= []
      vs[v.product_id] << v
      vs
    end
  end
end
