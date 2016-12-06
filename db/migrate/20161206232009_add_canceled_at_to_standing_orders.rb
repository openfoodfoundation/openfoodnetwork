class AddCanceledAtToStandingOrders < ActiveRecord::Migration
  def change
    add_column :standing_orders, :canceled_at, :datetime
  end
end
