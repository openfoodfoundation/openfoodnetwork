class SplitCustomersName < ActiveRecord::Migration[6.1]
  class Customer < ActiveRecord::Base
  end

  def change
    add_column :customers, :first_name, :string, null: false, default: ""
    add_column :customers, :last_name, :string, null: false, default: ""
    rename_column :customers, :name, :backup_name
    reversible do |dir|
      dir.up { migrate_customer_name_data }
    end
  end

  def migrate_customer_name_data
    Customer.includes(:bill_address).find_each do |customer|
      bill_address = customer.bill_address

      if bill_address.present? && bill_address.firstname.present? && bill_address.lastname?
        customer.first_name = bill_address.firstname.strip
        customer.last_name = bill_address.lastname.strip
      else
        first_name, last_name = customer.backup_name.strip.split(' ', 2)
        customer.first_name = first_name
        customer.last_name = last_name
      end

      customer.save
    end
  end
end