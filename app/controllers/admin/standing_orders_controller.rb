module Admin
  class StandingOrdersController < ResourceController
    before_filter :load_shop, only: [:new]

    respond_to :json

    respond_override create: { json: {
      success: lambda { render_as_json @standing_order },
      failure: lambda { render json: { errors: json_errors }, status: :unprocessable_entity }
    } }

    def new
      @standing_order = StandingOrder.new(shop: @shop)
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
  end
end
