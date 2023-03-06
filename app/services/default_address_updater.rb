# frozen_string_literal: true

class DefaultAddressUpdater
  def self.after_commit(order)
    return unless order.save_bill_address || order.save_ship_address

    new(order).call
  end

  def initialize(order)
    @order = order
  end

  def call
    assign_bill_addresses
    assign_ship_addresses

    customer&.save
    user&.save
  end

  private

  attr_reader :order

  delegate :save_ship_address, :save_bill_address, :customer, :user,
           :bill_address_id, :ship_address_id, to: :order

  def assign_bill_addresses
    return if save_bill_address == "0"

    customer.bill_address_id = bill_address_id
    user&.bill_address_id = bill_address_id
  end

  def assign_ship_addresses
    return if save_ship_address == "0"

    customer.ship_address_id = ship_address_id
    user&.ship_address_id = ship_address_id
  end
end
