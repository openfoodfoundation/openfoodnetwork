# frozen_string_literal: true

require 'spec_helper'

describe Api::Fast::CustomerSerializer do
  let(:customer) { create(:customer) }
  let(:serializer) { Api::Fast::CustomerSerializer.new(customer) }
  let(:json) { serializer.serializable_hash.as_json }

  it "serializes the object's basic info" do
    expect(json['data']['id']).to eq customer.id.to_s
    expect(json['data']['type']).to eq 'customer'
  end

  it "serializes the object's attributes" do
    expected_attributes = {
      'id' => customer.id,
      'enterprise_id' => customer.enterprise_id,
      'name' => customer.name,
      'code' => customer.code,
      'email' => customer.email,
      'allow_charges' => customer.allow_charges
    }

    expect(json['data']['attributes']).to eq expected_attributes
  end

  it "serializes relationship data" do
    expected_relationship = {
      'enterprise' => {
        'data' => {
          'id' => customer.enterprise_id.to_s,
          'type' => 'enterprise'
        }
      }
    }

    expect(json['data']['relationships']).to eq expected_relationship
  end
end
