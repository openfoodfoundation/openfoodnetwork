# frozen_string_literal: true

require 'open_food_network/permissions'
require 'open_food_network/order_cycle_permissions'
require 'open_food_network/scope_variant_to_hub'

module Admin
  class SubscriptionLineItemsController < Admin::ResourceController
    before_action :load_build_context, only: [:build]
    before_action :ensure_shop, only: [:build]
    before_action :ensure_variant, only: [:build]

    respond_to :json

    def build
      @subscription_line_item.assign_attributes(subscription_line_item_params)
      @subscription_line_item.price_estimate = price_estimate
      render json: @subscription_line_item, serializer: Api::Admin::SubscriptionLineItemSerializer,
             shop: @shop, schedule: @schedule
    end

    private

    def permissions
      OpenFoodNetwork::Permissions.new(spree_current_user)
    end

    def load_build_context
      @shop = Enterprise.managed_by(spree_current_user).find_by(id: params[:shop_id])
      @schedule = permissions.editable_schedules.find_by(id: params[:schedule_id])
      @order_cycle = @schedule&.current_or_next_order_cycle
      @variant = variant_if_eligible(subscription_line_item_params[:variant_id]) if @shop.present?
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

    def price_estimate
      return unless @order_cycle

      fee_calculator = OpenFoodNetwork::EnterpriseFeeCalculator.new(@shop, @order_cycle)
      OpenFoodNetwork::ScopeVariantToHub.new(@shop).scope(@variant)
      @variant.price + fee_calculator.indexed_fees_for(@variant)
    end

    def variant_if_eligible(variant_id)
      OrderManagement::Subscriptions::VariantsList.eligible_variants(@shop).find_by(id: variant_id)
    end

    def subscription_line_item_params
      params.require(:subscription_line_item).permit(:quantity, :variant_id)
    end
  end
end
