class AddTaxCategoryToVariants < ActiveRecord::Migration[7.0]
  def change
    add_reference :spree_variants, :tax_category, foreign_key: { to_table: :spree_tax_categories }
  end
end
