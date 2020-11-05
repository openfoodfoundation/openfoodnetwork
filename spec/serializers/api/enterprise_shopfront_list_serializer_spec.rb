# frozen_string_literal: true

require 'spec_helper'

describe Api::EnterpriseShopfrontListSerializer do
  let(:enterprise) { create(:distributor_enterprise) }
  let(:serializer) {
    Api::EnterpriseShopfrontListSerializer.new enterprise
  }

  it "serializes enterprise attributes" do
    expect(serializer.to_json).to match enterprise.name
  end

  it "serializes shopfront path" do
    expect(serializer.to_json).to match enterprise_shop_path(enterprise)
  end

  it "serializes icons" do
    expect(serializer.to_json).to match "map_005-hub.svg"
  end
end
