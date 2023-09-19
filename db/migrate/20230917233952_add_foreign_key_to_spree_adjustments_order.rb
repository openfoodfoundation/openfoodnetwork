class AddForeignKeyToSpreeAdjustmentsOrder < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_adjustments, :spree_orders, on_delete: :cascade
  end
end
