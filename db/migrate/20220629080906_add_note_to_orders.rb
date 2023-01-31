class AddNoteToOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_orders, :note, :string, null: false, default: ""
  end
end
