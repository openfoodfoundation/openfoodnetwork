class SplitCustomersName < ActiveRecord::Migration[6.1]
  class Customer < ActiveRecord::Base
  end

  def change
    add_column :customers, :first_name, :string
    add_column :customers, :last_name, :string
    rename_column :customers, :name, :backup_name
    reversible do |dir|
      dir.up { migrate_customer_name_data }
    end
  end

  def migrate_customer_name_data
    Customer.where("backup_name LIKE '% %'").find_each do |customer|
      first_name, last_name = customer.backup_name.split(' ', 2)
      customer.first_name = first_name
      customer.last_name = last_name
      customer.save
    end
  end
end