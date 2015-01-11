require 'spec_helper'

describe VariantOverride do
  let(:variant) { create(:variant) }
  let(:hub)     { create(:distributor_enterprise) }

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
    it "returns the numeric price when present" do
      VariantOverride.create!(variant: variant, hub: hub, price: 12.34)
      VariantOverride.price_for(hub, variant).should == 12.34
    end

    it "returns nil otherwise" do
      VariantOverride.price_for(hub, variant).should be_nil
    end
  end

  describe "looking up count on hand" do
    it "returns the numeric stock level when present" do
      VariantOverride.create!(variant: variant, hub: hub, count_on_hand: 12)
      VariantOverride.count_on_hand_for(hub, variant).should == 12
    end

    it "returns nil otherwise" do
      VariantOverride.count_on_hand_for(hub, variant).should be_nil
    end
  end

  describe "checking if stock levels have been overriden" do
    it "returns true when stock level has been overridden" do
      create(:variant_override, variant: variant, hub: hub, count_on_hand: 12)
      VariantOverride.stock_overridden?(hub, variant).should be_true
    end

    it "returns false when the override has no stock level" do
      create(:variant_override, variant: variant, hub: hub, count_on_hand: nil)
      VariantOverride.stock_overridden?(hub, variant).should be_false
    end

    it "returns false when there is no override for the hub/variant" do
      VariantOverride.stock_overridden?(hub, variant).should be_false
    end
  end

  describe "decrementing stock" do
    it "decrements stock" do
      vo = create(:variant_override, variant: variant, hub: hub, count_on_hand: 12)
      VariantOverride.decrement_stock! hub, variant, 2
      vo.reload.count_on_hand.should == 10
    end

    it "silently logs an error if the variant override doesn't have a stock level" do
      vo = create(:variant_override, variant: variant, hub: hub, count_on_hand: nil)
      Bugsnag.should_receive(:notify)
      VariantOverride.decrement_stock! hub, variant, 2
      vo.reload.count_on_hand.should be_nil
    end

    it "silently logs an error if the variant override does not exist" do
      Bugsnag.should_receive(:notify)
      VariantOverride.decrement_stock! hub, variant, 2
    end
  end
end
