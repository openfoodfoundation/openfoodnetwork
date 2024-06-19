class RequireTaxCategoryOnTaxRate < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_tax_rates, :tax_category_id, false
  end
end
