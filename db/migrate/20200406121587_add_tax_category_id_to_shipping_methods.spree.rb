# This migration comes from spree (originally 20140207085910)
class AddTaxCategoryIdToShippingMethods < ActiveRecord::Migration
  def change
    add_column :spree_shipping_methods, :tax_category_id, :integer
  end
end
