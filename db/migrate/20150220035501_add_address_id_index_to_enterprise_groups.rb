class AddAddressIdIndexToEnterpriseGroups < ActiveRecord::Migration
  def change
    add_index :enterprise_groups, :address_id
  end
end
