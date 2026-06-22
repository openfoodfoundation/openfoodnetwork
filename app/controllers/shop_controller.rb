# frozen_string_literal: true

class ShopController < BaseController
  layout "darkswarm"
  before_action :require_distributor_chosen, :set_order_cycles, except: :changeable_orders_alert

  def show
    redirect_to main_app.enterprise_shop_path(current_distributor)
  end

  def order_cycle
    if request.post?
      if oc = OrderCycle.with_distributor(@distributor).active.find_by(id: params[:order_cycle_id])
        current_order(true).assign_order_cycle! oc
        @current_order_cycle = oc
        render json: @current_order_cycle, serializer: Api::OrderCycleSerializer
      else
        render status: :not_found, json: ""
      end
    else
      render json: current_order_cycle, serializer: Api::OrderCycleSerializer
    end
  end

  def changeable_orders_alert
    render layout: false
  end

  def product_modal
    return head :not_found unless resolved_order_cycle&.open?

    @product = distributed_products_relation.find_by(id: params[:product_id])
    return head :not_found unless @product

    @supplier = @product.variants.first&.supplier
    @carousel_images = helpers.product_carousel_images_data(@product)

    render partial: "shop/product_modal", layout: false
  end

  private

  def distributed_products_relation
    OrderCycles::DistributedProductsService.new(
      current_distributor,
      resolved_order_cycle,
      current_customer,
      inventory_enabled: inventory_enabled?,
      variant_tag_enabled: variant_tag_enabled?
    ).products_relation
  end

  def resolved_order_cycle
    return @resolved_order_cycle if defined?(@resolved_order_cycle)

    @resolved_order_cycle = OrderCycle.find_by(id: params[:order_cycle_id])
  end

  def inventory_enabled?
    OpenFoodNetwork::FeatureToggle.enabled?(:inventory, current_distributor)
  end

  def variant_tag_enabled?
    OpenFoodNetwork::FeatureToggle.enabled?(:variant_tag, current_distributor)
  end
end
