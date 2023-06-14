# frozen_string_literal: true

class RequireShippingMethodAndDistributorOnDistributorShippingMethods < ActiveRecord::Migration[7.0]
  def change
    change_column_null :distributors_shipping_methods, :shipping_method_id, false
    change_column_null :distributors_shipping_methods, :distributor_id, false
  end
end
