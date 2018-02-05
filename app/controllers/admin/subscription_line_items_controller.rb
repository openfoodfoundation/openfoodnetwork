require 'open_food_network/permissions'
require 'open_food_network/order_cycle_permissions'

module Admin
  class StandingLineItemsController < ResourceController
    before_filter :load_build_context, only: [:build]
    before_filter :ensure_shop, only: [:build]
    before_filter :ensure_variant, only: [:build]

    respond_to :json

    def build
      @standing_line_item.assign_attributes(params[:standing_line_item])
      fee_calculator = OpenFoodNetwork::EnterpriseFeeCalculator.new(@shop, @order_cycle) if @order_cycle
      OpenFoodNetwork::ScopeVariantToHub.new(@shop).scope(@variant)
      render json: @standing_line_item, serializer: Api::Admin::StandingLineItemSerializer, fee_calculator: fee_calculator
    end

    private

    def permissions
      OpenFoodNetwork::Permissions.new(spree_current_user)
    end

    def load_build_context
      @shop = Enterprise.managed_by(spree_current_user).find_by_id(params[:shop_id])
      @schedule = permissions.editable_schedules.find_by_id(params[:schedule_id])
      @order_cycle = @schedule.andand.current_or_next_order_cycle
      @variant = Spree::Variant.stockable_by(@shop).find_by_id(params[:standing_line_item][:variant_id])
    end

    def new_actions
      [:new, :create, :build] # Added build
    end

    def ensure_shop
      return if @shop
      render json: { errors: ['Unauthorised'] }, status: :unauthorized
    end

    def ensure_variant
      return if @variant
      error = "#{@shop.name} is not permitted to sell the selected product"
      render json: { errors: [error] }, status: :unprocessable_entity
    end
  end
end
