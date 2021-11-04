class AddCustomerNamesToEnterprise < ActiveRecord::Migration[6.1]
  def change
    add_column :enterprises, :show_customer_names_to_suppliers,
               :boolean, null: false, default: false
  end
end
