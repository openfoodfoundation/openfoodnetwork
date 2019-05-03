# This migration comes from spree (originally 20130802014537)
class AddTaxCategoryIdToSpreeLineItems < ActiveRecord::Migration
  def change
    add_column :spree_line_items, :tax_category_id, :integer
  end
end
