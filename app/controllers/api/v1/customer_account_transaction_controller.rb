# frozen_string_literal: true

module Api
  module V1
    class CustomerAccountTransactionController < Api::V1::BaseController
      def create
        authorize! :create, CustomerAccountTransaction

        # We only allow using the api customer credit payment method
        default_params = {
          currency: CurrentConfig.get(:currency), payment_method_id:, created_by: current_api_user
        }
        transaction = CustomerAccountTransaction.new(
          default_params.merge(customer_account_transaction_params)
        )

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

      def payment_method_id
        Spree::PaymentMethod.internal.find_by(
          name: Rails.application.config.api_payment_method[:name]
        )&.id
      end
    end
  end
end
