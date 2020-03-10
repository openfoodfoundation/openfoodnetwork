require 'open_food_network/permissions'
require 'open_food_network/proxy_order_syncer'

module Admin
  class SubscriptionsController < ResourceController
    before_filter :load_shops, only: [:index]
    before_filter :load_form_data, only: [:new, :edit]
    before_filter :strip_banned_attrs, only: [:update]
    before_filter :wrap_nested_attrs, only: [:create, :update]
    before_filter :check_for_open_orders, only: [:cancel, :pause]
    before_filter :check_for_canceled_orders, only: [:unpause]
    respond_to :json

    def index
      respond_to do |format|
        format.html do
          if view_context.subscriptions_setup_complete?(@shops)
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
      @subscription.bill_address = Spree::Address.new
      @subscription.ship_address = Spree::Address.new
    end

    def create
      save_form_and_render(false)
    end

    def update
      save_form_and_render
    end

    def cancel
      @subscription.cancel(@open_orders_to_keep || [])

      respond_with(@subscription) do |format|
        format.json { render_as_json @subscription }
      end
    end

    def pause
      unless params[:open_orders] == 'keep'
        @subscription.proxy_orders.placed_and_open.each(&:cancel)
      end

      @subscription.update_attributes(paused_at: Time.zone.now)
      render_as_json @subscription
    end

    def unpause
      params[:subscription][:paused_at] = nil
      save_form_and_render
    end

    private

    def save_form_and_render(render_issues = true)
      form = SubscriptionForm.new(@subscription, subscription_params)
      unless form.save
        render json: { errors: form.json_errors }, status: :unprocessable_entity
        return
      end

      if render_issues
        render_as_json @subscription, order_update_issues: form.order_update_issues
      else
        render_as_json @subscription
      end
    end

    def permissions
      return @permissions unless @permissions.nil?

      @permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    end

    def collection
      if request.format.json?
        permissions.editable_subscriptions.ransack(params[:q]).result
          .preload([:shop, :customer, :schedule, :subscription_line_items, :ship_address, :bill_address, proxy_orders: { order: :order_cycle }])
      else
        Subscription.where("1=0")
      end
    end

    def load_shops
      @shops = Enterprise.managed_by(spree_current_user).is_distributor.where(enable_subscriptions: true)
    end

    def load_form_data
      @customers = Customer.of(@subscription.shop)
      @schedules = Schedule.with_coordinator(@subscription.shop)
      @payment_methods = Spree::PaymentMethod.for_distributor(@subscription.shop).for_subscriptions
      @shipping_methods = Spree::ShippingMethod.for_distributor(@subscription.shop)
      @order_cycles = OrderCycle.joins(:schedules).managed_by(spree_current_user)
    end

    # Wrap :subscription_line_items_attributes in :subscription root
    def wrap_nested_attrs
      if params[:subscription_line_items].is_a? Array
        attributes = params[:subscription_line_items].map do |sli|
          sli.slice(*SubscriptionLineItem.attribute_names + ["_destroy"])
        end
        params[:subscription][:subscription_line_items_attributes] = attributes
      end
      wrap_bill_address_attrs if params[:bill_address]
      wrap_ship_address_attrs if params[:ship_address]
    end

    def wrap_bill_address_attrs
      params[:subscription][:bill_address_attributes] = params[:bill_address].slice(*Spree::Address.attribute_names)
    end

    def wrap_ship_address_attrs
      params[:subscription][:ship_address_attributes] = params[:ship_address].slice(*Spree::Address.attribute_names)
    end

    def check_for_open_orders
      return if params[:open_orders] == 'cancel'

      @open_orders_to_keep = @subscription.proxy_orders.placed_and_open.pluck(:id)
      return if @open_orders_to_keep.empty? || params[:open_orders] == 'keep'

      render json: { errors: { open_orders: t('admin.subscriptions.confirm_cancel_open_orders_msg') } }, status: :conflict
    end

    def check_for_canceled_orders
      return if params[:canceled_orders] == 'notified'
      return if @subscription.proxy_orders.active.canceled.empty?

      render json: { errors: { canceled_orders: t('admin.subscriptions.resume_canceled_orders_msg') } }, status: :conflict
    end

    def strip_banned_attrs
      params[:subscription].delete :schedule_id
      params[:subscription].delete :customer_id
    end

    # Overriding Spree method to load data from params here so that
    # we can authorise #create using an object with required attributes
    def build_resource
      Subscription.new(subscription_params)
    end

    def ams_prefix_whitelist
      [:index]
    end

    def subscription_params
      return params[:subscription] if params[:subscription].empty?

      params.require(:subscription).permit(
        :id, :shop_id, :schedule_id, :customer_id,
        :payment_method_id, :shipping_method_id,
        :begins_at, :ends_at,
        :canceled_at, :paused_at,
        :shipping_fee_estimate, :payment_fee_estimate,
        :subscription_line_items_attributes => [:id, :quantity, :variant_id, :price_estimate, :_destroy],
        :bill_address_attributes => permitted_address_attributes,
        :ship_address_attributes => permitted_address_attributes
      )
    end
  end
end
