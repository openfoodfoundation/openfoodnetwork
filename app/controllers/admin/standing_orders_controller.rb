require 'open_food_network/permissions'

module Admin
  class StandingOrdersController < ResourceController
    before_filter :load_shops, only: [:index]
    before_filter :load_form_data, only: [:new, :edit]
    before_filter :strip_banned_attrs, only: [:update]
    before_filter :wrap_nested_attrs, only: [:create, :update]
    respond_to :json

    def index
      respond_to do |format|
        format.html do
          @order_cycles = OrderCycle.joins(:schedules).managed_by(spree_current_user)
          @payment_methods = Spree::PaymentMethod.managed_by(spree_current_user)
          @shipping_methods = Spree::ShippingMethod.managed_by(spree_current_user)
        end
        format.json { render_as_json @collection, ams_prefix: params[:ams_prefix] }
      end
    end

    def new
      @standing_order.bill_address = Spree::Address.new
      @standing_order.ship_address = Spree::Address.new
    end

    def create
      form = StandingOrderForm.new(@standing_order, params[:standing_order], fee_calculator)
      if form.save
        render_as_json @standing_order, fee_calculator: fee_calculator
      else
        render json: { errors: form.json_errors }, status: :unprocessable_entity
      end
    end

    def update
      form = StandingOrderForm.new(@standing_order, params[:standing_order], fee_calculator)
      if form.save
        render_as_json @standing_order, ams_prefix: params[:ams_prefix], fee_calculator: fee_calculator
      else
        render json: { errors: form.json_errors }, status: :unprocessable_entity
      end
    end

    private

    def permissions
      return @permissions unless @permissions.nil?
      @permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    end

    def collection
      if request.format.json?
        permissions.editable_standing_orders.ransack(params[:q]).result
        .preload([:shop,:customer,:schedule,:standing_line_items,:ship_address,:bill_address,standing_order_orders: {order: :order_cycle}])
      else
        StandingOrder.where("1=0")
      end
    end

    def load_shops
      @shops = Enterprise.managed_by(spree_current_user).is_distributor
    end

    def load_form_data
      @customers = Customer.of(@standing_order.shop)
      @schedules = Schedule.with_coordinator(@standing_order.shop)
      @payment_methods = Spree::PaymentMethod.for_distributor(@standing_order.shop)
      @shipping_methods = Spree::ShippingMethod.for_distributor(@standing_order.shop)
      @fee_calculator = fee_calculator
    end

    def fee_calculator
      shop, next_oc = @standing_order.shop, @standing_order.schedule.andand.current_or_next_order_cycle
      return nil unless shop && next_oc
      OpenFoodNetwork::EnterpriseFeeCalculator.new(shop, next_oc)
    end

    # Wrap :standing_line_items_attributes in :standing_order root
    def wrap_nested_attrs
      if params[:standing_line_items].is_a? Array
        attributes = params[:standing_line_items].map do |sli|
          sli.slice(*StandingLineItem.attribute_names + ["_destroy"])
        end
        params[:standing_order][:standing_line_items_attributes] = attributes
      end
      if bill_address_attrs = params[:bill_address]
        params[:standing_order][:bill_address_attributes] = bill_address_attrs.slice(*Spree::Address.attribute_names)
      end
      if ship_address_attrs = params[:ship_address]
        params[:standing_order][:ship_address_attributes] = ship_address_attrs.slice(*Spree::Address.attribute_names)
      end
    end

    def strip_banned_attrs
      params[:standing_order].delete :schedule_id
      params[:standing_order].delete :customer_id
    end

    # Overriding Spree method to load data from params here so that
    # we can authorise #create using an object with required attributes
    def build_resource
      StandingOrder.new(params[:standing_order])
    end

    def ams_prefix_whitelist
      [:index]
    end
  end
end
