class AddCart < ActiveRecord::Migration
  def change
    create_table :carts do |t|
      t.integer :user_id
    end

    add_column :spree_orders, :cart_id, :integer
  end
end
