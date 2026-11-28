# frozen_string_literal: true

# Splits the single "customers can change orders" setting into three separate
# permissions. The old allow_order_changes column is kept for now and is backfilled
# from in BackfillOrderChangePermissionsOnEnterprises. It will be dropped later,
# once no running code reads it.
class AddOrderChangePermissionsToEnterprises < ActiveRecord::Migration[8.0]
  def change
    change_table :enterprises, bulk: true do |t|
      t.boolean :allow_order_additions, default: false, null: false
      t.boolean :allow_order_removals, default: false, null: false
      t.boolean :allow_order_cancellation, default: false, null: false
    end
  end
end
