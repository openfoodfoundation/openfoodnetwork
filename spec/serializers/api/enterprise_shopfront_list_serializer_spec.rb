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

  describe '#icon' do
    context "enterpise has a unrecognized category" do
      before do
        allow(enterprise).to receive(:category) { "unknown_category" }
      end

      it "returns the map producer icon" do
        expect(serializer.icon).to eq("/map_icons/map_001-producer-only.svg")
      end
    end

    context "enterpise has a nil category" do
      before do
        allow(enterprise).to receive(:category) { nil }
      end

      it "returns the map producer icon" do
        expect(serializer.icon).to eq("/map_icons/map_001-producer-only.svg")
      end
    end
  end
end
