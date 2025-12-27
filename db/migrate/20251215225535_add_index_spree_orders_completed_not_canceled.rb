# frozen_string_literal: true

class AddIndexSpreeOrdersCompletedNotCanceled < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_index :spree_orders,
              [:distributor_id, :order_cycle_id],
              where: "completed_at IS NOT NULL AND state != 'canceled'",
              name: "idx_spree_orders_completed_not_canceled",
              algorithm: :concurrently
  end

  def down
    remove_index :spree_orders,
                 name: "idx_spree_orders_completed_not_canceled",
                 algorithm: :concurrently
  end
end
