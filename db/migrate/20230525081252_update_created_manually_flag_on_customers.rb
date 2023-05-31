# frozen_string_literal: true

class UpdateCreatedManuallyFlagOnCustomers < ActiveRecord::Migration[7.0]
  class Customer < ApplicationRecord
    has_many :orders
  end

  class Order < ApplicationRecord
    self.table_name = 'spree_orders'
  end

  def up
    Customer.where.missing(:orders).update_all(created_manually: true)
  end

  def down
    Customer.where(created_manually: true).update_all(created_manually: false)
  end
end
