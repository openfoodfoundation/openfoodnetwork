# frozen_string_literal: true

module Api
  module V1
    class CustomerAccountTransactionController < Api::V1::BaseController
      def create
        authorize! :create, CustomerAccountTransaction

        default_params = {
          currency: CurrentConfig.get(:currency), created_by: current_api_user
        }
        parameters = default_params.merge(customer_account_transaction_params).merge(description: )
        transaction = CustomerAccountTransaction.new(parameters)

        if transaction.save
          render json: Api::V1::CustomerAccountTransactionSerializer.new(transaction),
                 status: :created
        else
          invalid_resource! transaction
        end
      end

      private

      def customer_account_transaction_params
        params.require(:customer_account_transaction).permit(:customer_id, :amount, :description)
      end

      def description
        I18n.t(".api_customer_credit", description: params[:description])
      end
    end
  end
end
