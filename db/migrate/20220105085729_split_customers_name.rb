class SplitCustomersName < ActiveRecord::Migration[6.1]
  class SpreeAddress < ApplicationRecord
  end
  class Customer < ApplicationRecord
    belongs_to :bill_address, class_name: "SpreeAddress"
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
    Customer.where(first_name: "", last_name: "").where.not(backup_name: [nil, ""]).find_each do |customer|
      name_words = customer.backup_name.split(' ')
      next if name_words.empty?

      customer.update(
        first_name: name_words.first,
        last_name: name_words[1..].join(' ')
      )
    end
  end
end
