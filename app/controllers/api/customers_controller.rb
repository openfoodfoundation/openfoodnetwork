module Api
  class CustomersController < Api::BaseController
    skip_authorization_check only: :index

    def index
      @customers = current_api_user.customers
      render json: @customers, each_serializer: CustomerSerializer
    end

    def update
      @customer = Customer.find(params[:id])
      authorize! :update, @customer

      if @customer.update(params[:customer])
        render json: @customer, serializer: CustomerSerializer, status: :ok
      else
        invalid_resource!(@customer)
      end
    end
  end
end
