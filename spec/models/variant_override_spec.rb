require 'spec_helper'

describe VariantOverride do
  describe "scopes" do
    let(:hub1) { create(:distributor_enterprise) }
    let(:hub2) { create(:distributor_enterprise) }
    let(:v) { create(:variant) }
    let!(:vo1) { create(:variant_override, hub: hub1, variant: v) }
    let!(:vo2) { create(:variant_override, hub: hub2, variant: v) }

    it "finds variant overrides for a set of hubs" do
      VariantOverride.for_hubs([hub1, hub2]).sort.should == [vo1, vo2].sort
    end
  end

  describe "looking up prices" do
    let(:variant) { create(:variant) }
    let(:hub)     { create(:distributor_enterprise) }

    it "returns the numeric price when present" do
      VariantOverride.create!(variant: variant, hub: hub, price: 12.34)
      VariantOverride.price_for(hub, variant).should == 12.34
    end

    it "returns nil otherwise" do
      VariantOverride.price_for(hub, variant).should be_nil
    end
  end

  describe "looking up count on hand" do
    let(:variant) { create(:variant) }
    let(:hub)     { create(:distributor_enterprise) }

    it "returns the numeric stock level when present" do
      VariantOverride.create!(variant: variant, hub: hub, count_on_hand: 12)
      VariantOverride.count_on_hand_for(hub, variant).should == 12
    end

    it "returns nil otherwise" do
      VariantOverride.count_on_hand_for(hub, variant).should be_nil
    end
  end
end
