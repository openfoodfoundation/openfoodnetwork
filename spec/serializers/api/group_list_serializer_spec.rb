# frozen_string_literal: true

require 'spec_helper'

describe Api::GroupListSerializer do
  let!(:group) { create(:enterprise_group) }
  let!(:producer) { create(:supplier_enterprise) }

  let(:serializer) { Api::GroupListSerializer.new group }

  before do
    group.enterprises << producer
  end

  it "serializes group attributes" do
    expect(serializer.serializable_hash[:name]).to match group.name
  end

  it "serializes abbreviated state" do
    expect(serializer.serializable_hash[:state]).to eq group.address.state.abbr
  end

  it "serializes an array of enterprises" do
    expect(serializer.serializable_hash[:enterprises]).to be_a ActiveModel::ArraySerializer
    expect(serializer.serializable_hash[:enterprises].to_json).to match producer.name
  end
end
