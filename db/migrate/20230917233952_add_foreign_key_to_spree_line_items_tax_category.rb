class AddForeignKeyToSpreeLineItemsTaxCategory < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_line_items, :spree_tax_categories, on_delete: :cascade
  end
end
