module Admin
  class StandingOrdersController < ResourceController
    before_filter :load_enterprise, only: [:new]

    respond_to :json

    respond_override create: { json: {
      success: lambda { render_as_json @standing_order },
      failure: lambda { render json: { errors: json_errors }, status: :unprocessable_entity }
    } }

    def new
      @customers = Customer.of(@enterprise)
      @schedules = Schedule.with_coordinator(@enterprise)
      @payment_methods = Spree::PaymentMethod.for_distributor(@enterprise)
      @shipping_methods = Spree::ShippingMethod.for_distributor(@enterprise)
    end

    private

    def load_enterprise
      @enterprise = Enterprise.find_by_permalink! params[:enterprise_id]
    end

    def json_errors
      @object.errors.messages.inject({}) do |errors, (k,v)|
        errors[k] = v.map{ |msg| @object.errors.full_message(k,msg) }
        errors
      end
    end
  end
end
