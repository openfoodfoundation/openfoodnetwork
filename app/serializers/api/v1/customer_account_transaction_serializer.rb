# frozen_string_literal: true

module Api
  module V1
    class CustomerAccountTransactionSerializer < Api::V1::BaseSerializer
      attributes :id, :customer_id, :payment_method_id, :amount, :currency, :description, :balance
    end
  end
end
