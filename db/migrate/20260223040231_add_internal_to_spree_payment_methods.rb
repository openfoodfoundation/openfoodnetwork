# frozen_string_literal: true

class AddInternalToSpreePaymentMethods < ActiveRecord::Migration[7.1]
  def change
    add_column :spree_payment_methods, :internal, :boolean, null: false, default: false
  end
end
