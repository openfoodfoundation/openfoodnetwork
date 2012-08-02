class AddGroupBuyFields < ActiveRecord::Migration
  def change
    add_column :spree_products, :group_buy, :boolean
    add_column :spree_line_items, :max_quantity, :integer
  end
end
