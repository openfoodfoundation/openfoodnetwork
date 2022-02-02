class SplitCustomersName < ActiveRecord::Migration[6.1]
  class Spree::DummyAddress < ApplicationRecord
    self.table_name = 'spree_addresses'
  end
  class Customer < ApplicationRecord
    belongs_to :bill_address, class_name: "Spree::DummyAddress"
  end

  def up
    add_column :customers, :first_name, :string, null: false, default: ""
    add_column :customers, :last_name, :string, null: false, default: ""
    rename_column :customers, :name, :backup_name

    migrate_customer_name_data!
  end

  def down
    remove_column :customers, :first_name
    remove_column :customers, :last_name
    rename_column :customers, :backup_name, :name
  end

  def migrate_customer_name_data!
    Customer.includes(:bill_address).where.not(bill_address_id: nil).find_each do |customer|
      bill_address = customer.bill_address

      customer.first_name = bill_address.firstname.strip
      customer.last_name = bill_address.lastname.strip
      customer.save
    end

    Customer.where(first_name: "", last_name: "").where.not(backup_name: [nil, ""]).find_each do |customer|
      first_name, last_name = customer.backup_name.split(' ', 2)
      customer.first_name = first_name
      customer.last_name = last_name.to_s
      customer.save
    end
  end
end