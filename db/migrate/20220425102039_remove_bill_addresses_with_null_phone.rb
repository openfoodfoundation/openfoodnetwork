class RemoveBillAddressesWithNullPhone < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key "spree_users", "spree_addresses", column: "bill_address_id", name: "spree_users_bill_address_id_fk"
    add_foreign_key "spree_users", "spree_addresses", column: "bill_address_id", name: "spree_users_bill_address_id_fk", on_delete: :nullify
    execute("DELETE from spree_addresses WHERE phone IS NULL AND id IN(SELECT bill_address_id FROM spree_users)")
  end
end
