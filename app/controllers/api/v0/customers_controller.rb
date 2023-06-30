# frozen_string_literal: true

module Api
  module V0
    class CustomersController < Api::V0::BaseController
      skip_authorization_check only: :index

      def index
        @customers = current_api_user.customers.visible
        render json: @customers, each_serializer: CustomerSerializer
      end

      def update
        @customer = Customer.find(params[:id])
        authorize! :update, @customer

        client_secret = RecurringPayments.setup_for(@customer) if params[:customer][:allow_charges]

        if @customer.update(customer_params)
          add_recurring_payment_info(client_secret)
          render json: @customer, serializer: CustomerSerializer, status: :ok
        else
          invalid_resource!(@customer)
        end
      end

      private

      def add_recurring_payment_info(client_secret)
        return unless client_secret

        @customer.gateway_recurring_payment_client_secret = client_secret
        @customer.gateway_shop_id = @customer.enterprise.stripe_account&.stripe_user_id
      end

      def customer_params
        params.require(:customer).permit(:code, :email, :enterprise_id, :allow_charges)
      end
    end
  end
end
