# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/address_finder'

describe Api::Admin::SubscriptionCustomerSerializer do
  let(:address) { build(:address) }
  let(:customer) { build(:customer) }
  let(:serializer) { Api::Admin::SubscriptionCustomerSerializer.new(customer) }
  let(:finder_mock) {
    instance_double(OpenFoodNetwork::AddressFinder, bill_address: address, ship_address: address)
  }

  before do
    allow(serializer).to receive(:finder) { finder_mock }
  end

  it "serializes a customer " do
    result = JSON.parse(serializer.to_json)
    expect(result['email']).to eq customer.email
    expect(result['ship_address']['id']).to be nil
    expect(result['ship_address']['address1']).to eq address.address1
    expect(result['ship_address']['firstname']).to eq address.firstname
  end
end
