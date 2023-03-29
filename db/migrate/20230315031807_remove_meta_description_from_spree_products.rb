class RemoveMetaDescriptionFromSpreeProducts < ActiveRecord::Migration[6.1]
  def change
    remove_column :spree_products, :meta_description, :text
  end
end
