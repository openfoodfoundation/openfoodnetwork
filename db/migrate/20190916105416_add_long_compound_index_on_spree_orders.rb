class AddLongCompoundIndexOnSpreeOrders < ActiveRecord::Migration[4.2]
  def change
    add_index(
      :spree_orders,
      [:completed_at, :user_id, :created_by_id, :created_at],
      name: 'spree_orders_completed_at_user_id_created_by_id_created_at_idx'
    )
  end
end
