# frozen_string_literal: true

class RequirePaymentMethodAndDistributorOnDistributorPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    change_column_null :distributors_payment_methods, :payment_method_id, false
    change_column_null :distributors_payment_methods, :distributor_id, false
  end
end
