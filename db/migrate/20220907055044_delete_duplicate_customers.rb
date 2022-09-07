# frozen_string_literal: true

class DeleteDuplicateCustomers < ActiveRecord::Migration[6.1]
  class Customer < ActiveRecord::Base
    belongs_to :bill_address, class_name: "SpreeAddress", dependent: :destroy
    belongs_to :ship_address, class_name: "SpreeAddress", dependent: :destroy
  end

  class SpreeAddress < ActiveRecord::Base
  end

  class SpreeOrder < ActiveRecord::Base
  end

  class Subscription < ActiveRecord::Base
  end

  def up
    say "#{grouped_duplicates.keys.count} customers with duplicates."

    grouped_duplicates.map do |key, customers|
      chosen = customers.first
      others = customers - [chosen]

      say "- #{key}"

      # We can't tell which attributes or associations are the correct ones.
      # Selection has been random so far and it's no regression to randomly
      # select the attributes of the first customer record.
      #
      # However, we do need to update references to the customer.
      update_references(others, chosen)

      others.each(&:destroy!)
    end
  end

  def grouped_duplicates
    @grouped_duplicates ||= duplicate_records.group_by do |customer|
      [customer.email, customer.enterprise_id]
    end
  end

  def duplicate_records
    customer_duplicates = <<~SQL
      JOIN customers AS copy
        ON customers.id != copy.id
       AND customers.email = copy.email
       AND customers.enterprise_id = copy.enterprise_id
    SQL

    Customer.joins(customer_duplicates)
  end

  def update_references(source_customers, destination_customer)
    SpreeOrder.where(customer_id: source_customers.map(&:id)).
      update_all(customer_id: destination_customer.id)

    Subscription.where(customer_id: source_customers.map(&:id)).
      update_all(customer_id: destination_customer.id)
  end
end
