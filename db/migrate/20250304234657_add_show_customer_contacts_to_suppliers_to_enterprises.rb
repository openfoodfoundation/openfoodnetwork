# frozen_string_literal: true

class AddShowCustomerContactsToSuppliersToEnterprises < ActiveRecord::Migration[7.0]
  def change
    add_column :enterprises, :show_customer_contacts_to_suppliers, :boolean, default: false,
                                                                             null: false
  end
end
