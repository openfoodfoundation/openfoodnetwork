# frozen_string_literal: true

class UpdateCreatedManuallyFlagOnCustomers < ActiveRecord::Migration[7.0]
  class Customer < ApplicationRecord
    has_many :orders, class_name: "Spree::Order"
    acts_as_taggable
  end

  module Spree
    class Order < ApplicationRecord
      belongs_to :customer
      self.table_name = 'spree_orders'
    end
  end

  def change
    # We want to set the created_manually flag to true for all customers that don't have any orders
    Customer.where.not(id: customers_with_at_least_one_order)
      .update_all(created_manually: true)
  end

  def customers_with_at_least_one_order
    Spree::Order.pluck(:customer_id)
  end
end
