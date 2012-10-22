class AddGroupBuyUnitSizeToProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :group_buy_unit_size, :string
  end
end
