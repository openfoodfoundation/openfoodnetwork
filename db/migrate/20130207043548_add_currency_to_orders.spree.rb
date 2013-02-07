# This migration comes from spree (originally 20121107194006)
class AddCurrencyToOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :currency, :string
  end
end
