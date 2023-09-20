class AddForeignKeyToTagRulesEnterprises < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :enterprises, :spree_addresses, column: :business_address_id
  end
end
