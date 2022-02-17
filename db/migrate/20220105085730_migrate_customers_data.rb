# frozen_string_literal: true

class MigrateCustomersData < ActiveRecord::Migration[6.1]
  class SpreeAddress < ApplicationRecord; end

  class Customer < ApplicationRecord
    belongs_to :bill_address, class_name: "SpreeAddress"
  end

  def up
    migrate_customer_name_data!
  end

  def migrate_customer_name_data!
    customers_with_bill_addresses.find_each do |customer|
      if bill_address_name_matches?(customer)
        apply_name_from_bill_address!(customer)
        next
      end

      split_customer_name!(customer)
    end

    customers_without_bill_addresses.find_each do |customer|
      split_customer_name!(customer)
    end
  end

  def customers_with_bill_addresses
    Customer.joins(:bill_address).where(first_name: "", last_name: "").where.not(name: [nil, ""])
  end

  def customers_without_bill_addresses
    Customer.where(bill_address_id: nil, first_name: "", last_name: "").where.not(name: [nil, ""])
  end

  def bill_address_name_matches?(customer)
    address_name = customer.bill_address.firstname + customer.bill_address.lastname
    customer.name.delete(" ") == address_name.delete(" ")
  end

  def split_customer_name!(customer)
    return if (name_parts = customer.name.split(' ')).empty?

    customer.update_columns(
      first_name: name_parts.first,
      last_name: name_parts[1..].join(' '),
      updated_at: Time.zone.now
    )
  end

  def apply_name_from_bill_address!(customer)
    customer.update_columns(
      first_name: customer.bill_address.firstname,
      last_name: customer.bill_address.lastname,
      updated_at: Time.zone.now
    )
  end
end
