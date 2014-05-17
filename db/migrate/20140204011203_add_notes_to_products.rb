class AddNotesToProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :notes, :text
  end
end
