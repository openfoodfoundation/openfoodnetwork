class AddBusinessAddressIdToEnterprises < ActiveRecord::Migration[6.1]
  def change
    add_column :enterprises, :business_address_id, :integer
  end
end
