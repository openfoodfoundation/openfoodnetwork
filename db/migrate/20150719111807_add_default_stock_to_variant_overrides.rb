class AddDefaultStockToVariantOverrides < ActiveRecord::Migration
  def change
    add_column :variant_overrides, :default_stock, :integer
  end
end
