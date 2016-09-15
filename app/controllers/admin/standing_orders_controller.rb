module Admin
  class StandingOrdersController < ResourceController
    before_filter :load_shop, only: [:new]
    before_filter :wrap_sli_attrs, only: [:create]
    respond_to :json

    respond_override create: { json: {
      success: lambda { render_as_json @standing_order },
      failure: lambda { render json: { errors: json_errors }, status: :unprocessable_entity }
    } }

    def new
      @standing_order.shop = @shop
      @customers = Customer.of(@shop)
      @schedules = Schedule.with_coordinator(@shop)
      @payment_methods = Spree::PaymentMethod.for_distributor(@shop)
      @shipping_methods = Spree::ShippingMethod.for_distributor(@shop)
    end

    private

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
