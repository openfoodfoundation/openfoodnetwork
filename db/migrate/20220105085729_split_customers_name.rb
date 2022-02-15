# frozen_string_literal: true

class SplitCustomersName < ActiveRecord::Migration[6.1]
  class SpreeAddress < ApplicationRecord
  end

  class Customer < ApplicationRecord
    belongs_to :bill_address, class_name: "SpreeAddress"
  end

  def up
    add_column :customers, :first_name, :string, null: false, default: ""
    add_column :customers, :last_name, :string, null: false, default: ""

    migrate_customer_name_data!
  end

  def down
    remove_column :customers, :first_name
    remove_column :customers, :last_name
  end

  def migrate_customer_name_data!
    Customer.where(first_name: "", last_name: "").where.not(name: [nil, ""]).find_each do |customer|
      name_words = customer.name.split(' ')
      next if name_words.empty?

      customer.update(
        first_name: name_words.first,
        last_name: name_words[1..].join(' ')
      )
    end
  end
end
