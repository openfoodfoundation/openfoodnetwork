# This migration comes from spree (originally 20130301162745)
class RemoveShippingCategoryIdFromShippingMethod < ActiveRecord::Migration
  def change
    remove_column :spree_shipping_methods, :shipping_category_id
  end
end
