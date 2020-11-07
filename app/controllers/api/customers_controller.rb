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

      if @customer.update(customer_params)
        render json: @customer, serializer: CustomerSerializer, status: :ok
      else
        invalid_resource!(@customer)
      end
    end

    def customer_params
      params.require(:customer).permit(:code, :email, :enterprise_id, :allow_charges)
    end
  end
end
