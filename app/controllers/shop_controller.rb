require 'open_food_network/cached_products_renderer'

class ShopController < BaseController
  layout "darkswarm"
  before_filter :require_distributor_chosen
  before_filter :set_order_cycles

  def show
    redirect_to main_app.enterprise_shop_path(current_distributor)
  end

  def products
    begin
      renderer = OpenFoodNetwork::CachedProductsRenderer.new(current_distributor, current_order_cycle)

      # If we add any more filtering logic, we should probably
      # move it all to a lib class like 'CachedProductsFilterer'
      products_json = filtered_json(renderer.products_json)

      render json: products_json

    rescue OpenFoodNetwork::CachedProductsRenderer::NoProducts
      render status: 404, json: ''
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

  def filtered_json(products_json)
    tag_rules = relevant_tag_rules
    return apply_tag_rules(tag_rules, products_json) if tag_rules.any?
    products_json
  end

  def apply_tag_rules(tag_rules, products_json)
    products_hash = JSON.parse(products_json)
    current_distributor.apply_tag_rules(
      rules: tag_rules,
      subject: products_hash,
      customer_tags: current_order.andand.customer.andand.tag_list || []
    )
    JSON.unparse(products_hash)
  end

  def relevant_tag_rules
    TagRule.for(current_distributor).of_type("FilterProducts")
  end
end
