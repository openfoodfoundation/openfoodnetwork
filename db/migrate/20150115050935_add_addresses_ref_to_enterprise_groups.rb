class AddAddressesRefToEnterpriseGroups < ActiveRecord::Migration
  def change
    add_column :enterprise_groups, :address_id, :integer
    add_foreign_key :enterprise_groups, :spree_addresses, name: "enterprise_groups_address_id_fk", column: "address_id"
  end
end
