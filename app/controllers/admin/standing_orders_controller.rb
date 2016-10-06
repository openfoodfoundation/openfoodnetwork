require 'open_food_network/permissions'

module Admin
  class StandingOrdersController < ResourceController
    before_filter :load_shop, only: [:new]
    before_filter :wrap_sli_attrs, only: [:create]
    respond_to :json

    respond_override create: { json: {
      success: lambda {
        shop, next_oc = @standing_order.shop, @standing_order.schedule.current_or_next_order_cycle
        fee_calculator = OpenFoodNetwork::EnterpriseFeeCalculator.new(shop, next_oc) if shop && next_oc
        render_as_json @standing_order, fee_calculator: fee_calculator
      },
      failure: lambda { render json: { errors: json_errors }, status: :unprocessable_entity }
    } }

    def index
      respond_to do |format|
        format.html
        format.json { render_as_json @collection, ams_prefix: params[:ams_prefix] }
      end
    end

    def new
      @standing_order.shop = @shop
      @customers = Customer.of(@shop)
      @schedules = Schedule.with_coordinator(@shop)
      @payment_methods = Spree::PaymentMethod.for_distributor(@shop)
      @shipping_methods = Spree::ShippingMethod.for_distributor(@shop)
    end

    private

    def permissions
      return @permissions unless @permissions.nil?
      @permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    end

    def collection
      if request.format.json?
        permissions.editable_standing_orders.ransack(params[:q]).result
        .preload([:shop,:customer,:payment_method,:shipping_method])
      else
        StandingOrder.where("1=0")
      end
    end

    def load_shop
      @shop = Enterprise.find(params[:shop_id])
    end

    def json_errors
      @object.errors.messages.inject({}) do |errors, (k,v)|
        errors[k] = v.map{ |msg| @object.errors.full_message(k,msg) }
        errors
      end
    end

    # Wrap :standing_line_items_attributes in :standing_order root
    def wrap_sli_attrs
      if params[:standing_line_items].is_a? Array
        attributes = params[:standing_line_items].map do |sli|
          sli.slice(*StandingLineItem.attribute_names)
        end
        params[:standing_order][:standing_line_items_attributes] = attributes
      end
    end

    # Overriding Spree method to load data from params here so that
    # we can authorise #create using an object with required attributes
    def build_resource
      StandingOrder.new(shop_id: params[:standing_order].andand[:shop_id])
    end
  end
end
