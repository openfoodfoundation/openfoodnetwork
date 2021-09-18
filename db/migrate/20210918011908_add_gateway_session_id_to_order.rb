class AddGatewaySessionIdToOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_orders, :gateway_checkout_session_id, :string
  end
end
