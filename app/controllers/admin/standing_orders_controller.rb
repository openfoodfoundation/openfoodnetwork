require 'open_food_network/permissions'

module Admin
  class StandingOrdersController < ResourceController
    before_filter :load_shops, only: [:index]
    before_filter :load_form_data, only: [:new, :edit]
    before_filter :strip_banned_attrs, only: [:update]
    before_filter :wrap_nested_attrs, only: [:create, :update]
    before_filter :check_for_open_orders, only: [:cancel, :pause]
    respond_to :json

    def index
      respond_to do |format|
        format.html do
          if view_context.standing_orders_setup_complete?(@shops)
            @order_cycles = OrderCycle.joins(:schedules).managed_by(spree_current_user)
            @payment_methods = Spree::PaymentMethod.managed_by(spree_current_user)
            @shipping_methods = Spree::ShippingMethod.managed_by(spree_current_user)
          else
            @shop = @shops.first
            render :setup_explanation
          end
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
        render_as_json @standing_order, fee_calculator: fee_calculator, order_update_issues: form.order_update_issues
      else
        render json: { errors: form.json_errors }, status: :unprocessable_entity
      end
    end

    def cancel
      @standing_order.cancel(@open_orders_to_keep || [])

      respond_with(@standing_order) do |format|
        format.json { render_as_json @standing_order, fee_calculator: fee_calculator }
      end
    end

    def pause
      unless params[:open_orders] == 'keep'
        @standing_order.proxy_orders.placed_and_open.each(&:cancel)
      end

      @standing_order.update_attributes(paused_at: Time.zone.now)
      render_as_json @standing_order, fee_calculator: fee_calculator
    end

    def unpause
      @standing_order.update_attributes(paused_at: nil)
      render_as_json @standing_order, fee_calculator: fee_calculator
    end

    private

    def permissions
      return @permissions unless @permissions.nil?
      @permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    end

    def collection
      if request.format.json?
        permissions.editable_standing_orders.ransack(params[:q]).result
        .preload([:shop,:customer,:schedule,:standing_line_items,:ship_address,:bill_address,proxy_orders: {order: :order_cycle}])
      else
        StandingOrder.where("1=0")
      end
    end

    def load_shops
      @shops = Enterprise.managed_by(spree_current_user).is_distributor.where(enable_standing_orders: true)
    end

    def load_form_data
      @customers = Customer.of(@standing_order.shop)
      @schedules = Schedule.with_coordinator(@standing_order.shop)
      @payment_methods = Spree::PaymentMethod.for_distributor(@standing_order.shop)
      @shipping_methods = Spree::ShippingMethod.for_distributor(@standing_order.shop)
      @order_cycles = OrderCycle.joins(:schedules).managed_by(spree_current_user)
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

    def check_for_open_orders
      return if params[:open_orders] == 'cancel'
      @open_orders_to_keep = @standing_order.proxy_orders.placed_and_open.pluck(:id)
      return if @open_orders_to_keep.empty? || params[:open_orders] == 'keep'
      return render json: { errors: { open_orders: t('admin.standing_orders.confirm_cancel_open_orders_msg') } }, status: :conflict
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
