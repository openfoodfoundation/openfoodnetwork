class AddTaxCategoryToAdjustments < ActiveRecord::Migration[5.0]
  def change
    add_column :spree_adjustments, :tax_category_id, :integer
    add_index :spree_adjustments, :tax_category_id
  end
end
