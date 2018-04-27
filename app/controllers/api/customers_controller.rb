module Api
  class CustomersController < BaseController
    def index
      @customers = current_api_user.customers
      render json: @customers, each_serializer: CustomerSerializer
    end

    def update
      @customer = Customer.find(params[:id])
      authorize! :update, @customer

      if @customer.update_attributes(params[:customer])
        render json: @customer, serializer: CustomerSerializer, status: 200
      else
        invalid_resource!(@customer)
      end
    end
  end
end
