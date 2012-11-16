class ChangeGroupBuyUnitSizeFromStringToFloat < ActiveRecord::Migration
  class Spree::Product < ActiveRecord::Base; end

  def up
    add_column :spree_products, :group_buy_unit_size_f, :float
    Spree::Product.reset_column_information

    Spree::Product.all.each do |product|
      product.group_buy_unit_size_f = product.group_buy_unit_size.to_f
      product.save!
    end

    remove_column :spree_products, :group_buy_unit_size
    rename_column :spree_products, :group_buy_unit_size_f, :group_buy_unit_size
  end

  def down
    change_column :spree_products, :group_buy_unit_size, :string
  end

end
