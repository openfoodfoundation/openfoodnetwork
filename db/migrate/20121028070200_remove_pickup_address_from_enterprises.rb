class RemovePickupAddressFromEnterprises < ActiveRecord::Migration
  def change
    remove_column :enterprises, :pickup_address_id
  end
end
