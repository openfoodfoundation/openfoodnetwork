# frozen_string_literal: true

module Spree
  class ReturnAuthorization < ApplicationRecord
    self.belongs_to_required_by_default = false

    acts_as_paranoid

    belongs_to :order, class_name: 'Spree::Order', inverse_of: :return_authorizations

    has_many :inventory_units, inverse_of: :return_authorization
    has_one :stock_location
    before_save :force_positive_amount
    before_create :generate_number

    validates :order, presence: true
    validates :amount, numericality: true
    validate :must_have_shipped_units

    state_machine initial: :authorized do
      after_transition to: :received, do: :process_return

      event :receive do
        transition to: :received, from: :authorized, if: :allow_receive?
      end
      event :cancel do
        transition to: :canceled, from: :authorized
      end
    end

    def currency
      order.nil? ? Spree::Config[:currency] : order.currency
    end

    def display_amount
      Spree::Money.new(amount, currency: currency)
    end

    def add_variant(variant_id, quantity)
      order_units = returnable_inventory.group_by(&:variant_id)
      returned_units = inventory_units.group_by(&:variant_id)
      return false if order_units.empty?

      count = 0

      if returned_units[variant_id].nil? || returned_units[variant_id].size < quantity
        count = returned_units[variant_id].nil? ? 0 : returned_units[variant_id].size

        order_units[variant_id].each do |inventory_unit|
          next unless inventory_unit.return_authorization.nil? && count < quantity

          inventory_unit.return_authorization = self
          inventory_unit.save!

          count += 1
        end
      elsif returned_units[variant_id].size > quantity
        (returned_units[variant_id].size - quantity).times do |i|
          returned_units[variant_id][i].return_authorization_id = nil
          returned_units[variant_id][i].save!
        end
      end

      order.authorize_return! if !inventory_units.reload.empty? && !order.awaiting_return?
    end

    def returnable_inventory
      order.shipments.shipped.collect{ |s| s.inventory_units.to_a }.flatten
    end

    # Used when Adjustment#update_adjustment! wants to update the related adjustment
    def compute_amount(*_args)
      -amount.abs
    end

    private

    def must_have_shipped_units
      return unless order.nil? || order.shipments.shipped.none?

      errors.add(:order, Spree.t(:has_no_shipped_units))
    end

    def generate_number
      return if number

      record = true
      while record
        random = "RMA#{Array.new(9){ rand(9) }.join}"
        record = self.class.find_by(number: random)
      end
      self.number = random
    end

    def process_return
      inventory_units.each do |iu|
        iu.return!
        Spree::StockMovement.create!(stock_item_id: iu.find_stock_item.id, quantity: 1)
      end

      Adjustment.create(
        amount: -amount.abs,
        label: I18n.t('spree.rma_credit'),
        order: order,
        adjustable: order,
        originator: self
      )

      order.return if inventory_units.all?(&:returned?)
      order.update_order!
    end

    def allow_receive?
      !inventory_units.empty?
    end

    def force_positive_amount
      self.amount = amount.abs
    end
  end
end
