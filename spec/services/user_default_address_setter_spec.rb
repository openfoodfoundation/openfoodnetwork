# frozen_string_literal: true

require 'spec_helper'

describe UserDefaultAddressSetter do
  let(:customer_address) { create(:address, address1: "customer road") }
  let(:order_address) { create(:address, address1: "order road") }
  let(:customer) do
    create(:customer, bill_address: customer_address, ship_address: customer_address)
  end
  let(:order) do
    create(:order, customer: customer, bill_address: order_address, ship_address: order_address)
  end
  let(:user) { create(:user) }

  let(:setter) { UserDefaultAddressSetter.new(order, user) }

  describe '#set_default_bill_address' do
    it "sets the user and customer bill address to the order bill address" do
      setter.set_default_bill_address

      expect(user.bill_address).to eq order.bill_address
      expect(order.customer.bill_address).to eq order.bill_address
    end
  end

  describe '#set_default_ship_address' do
    it "sets the user and customer ship address to the order ship address" do
      setter.set_default_ship_address

      expect(user.ship_address).to eq order.ship_address
      expect(order.customer.ship_address).to eq order.ship_address
    end
  end
end
