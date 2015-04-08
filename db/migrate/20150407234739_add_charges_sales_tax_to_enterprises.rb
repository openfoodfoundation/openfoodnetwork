class AddChargesSalesTaxToEnterprises < ActiveRecord::Migration
  def change
    add_column :enterprises, :charges_sales_tax, :boolean, null: false, default: false
  end
end
