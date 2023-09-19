class AddForeignKeyToSpreeAdjustmentsTaxCategory < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_adjustments, :spree_tax_categories, on_delete: :cascade
  end
end
