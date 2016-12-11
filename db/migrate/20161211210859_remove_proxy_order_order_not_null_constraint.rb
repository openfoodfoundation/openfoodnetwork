class RemoveProxyOrderOrderNotNullConstraint < ActiveRecord::Migration
  def up
    change_column :proxy_orders, :order_id, :integer, null: true
  end

  def down
    change_column :proxy_orders, :order_id, :integer, null: false
  end
end
