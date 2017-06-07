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
    let!(:vo3) { create(:variant_override, hub: hub1, variant: v, permission_revoked_at: Time.now) }

    it "ignores variant_overrides with revoked_permissions by default" do
      expect(VariantOverride.all).to_not include vo3
      expect(VariantOverride.unscoped).to include vo3
    end

    it "finds variant overrides for a set of hubs" do
      VariantOverride.for_hubs([hub1, hub2]).should match_array [vo1, vo2]
    end

    describe "fetching variant overrides indexed by variant" do
      it "gets indexed variant overrides for one hub" do
        VariantOverride.indexed(hub1).should == {v => vo1}
        VariantOverride.indexed(hub2).should == {v => vo2}
      end
    end
  end


  describe "callbacks" do
    let!(:vo) { create(:variant_override, hub: hub, variant: variant) }

    it "refreshes the products cache on save" do
      expect(OpenFoodNetwork::ProductsCache).to receive(:variant_override_changed).with(vo)
      vo.price = 123.45
      vo.save
    end

    it "refreshes the products cache on destroy" do
      expect(OpenFoodNetwork::ProductsCache).to receive(:variant_override_destroyed).with(vo)
      vo.destroy
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
      VariantOverride.stock_overridden?(hub, variant).should be true
    end

    it "returns false when the override has no stock level" do
      create(:variant_override, variant: variant, hub: hub, count_on_hand: nil)
      VariantOverride.stock_overridden?(hub, variant).should be false
    end

    it "returns false when there is no override for the hub/variant" do
      VariantOverride.stock_overridden?(hub, variant).should be false
    end
  end

  describe "decrementing stock" do
    it "decrements stock" do
      vo = create(:variant_override, variant: variant, hub: hub, count_on_hand: 12)
      VariantOverride.decrement_stock! hub, variant, 2
      vo.reload.count_on_hand.should == 10
    end

    it "silently logs an error if the variant override does not exist" do
      Bugsnag.should_receive(:notify)
      VariantOverride.decrement_stock! hub, variant, 2
    end
  end

  describe "incrementing stock" do
    let!(:vo) { create(:variant_override, variant: variant, hub: hub, count_on_hand: 8) }

    context "when the vo overrides stock" do
      it "increments stock" do
        vo.increment_stock! 2
        vo.reload.count_on_hand.should == 10
      end
    end

    context "when the vo doesn't override stock" do
      before { vo.update_attributes(count_on_hand: nil) }

      it "silently logs an error" do
        Bugsnag.should_receive(:notify)
        vo.increment_stock! 2
      end
    end
  end

  describe "checking default stock value is present" do
    it "returns true when a default stock level has been set"  do
      vo = create(:variant_override, variant: variant, hub: hub, count_on_hand: 12, default_stock: 20)
      vo.default_stock?.should be true
    end

    it "returns false when the override has no default stock level" do
      vo = create(:variant_override, variant: variant, hub: hub, count_on_hand: 12, default_stock:nil)
      vo.default_stock?.should be false
    end
  end

  describe "resetting stock levels" do
    it "resets the on hand level to the value in the default_stock field" do
      vo = create(:variant_override, variant: variant, hub: hub, count_on_hand: 12, default_stock: 20, resettable: true)
      vo.reset_stock!
      vo.reload.count_on_hand.should == 20
    end
    it "silently logs an error if the variant override doesn't have a default stock level" do
      vo = create(:variant_override, variant: variant, hub: hub, count_on_hand: 12, default_stock:nil, resettable: true)
      Bugsnag.should_receive(:notify)
      vo.reset_stock!
      vo.reload.count_on_hand.should == 12
    end
    it "doesn't reset the level if the behaviour is disabled" do
      vo = create(:variant_override, variant: variant, hub: hub, count_on_hand: 12, default_stock: 10, resettable: false)
      vo.reset_stock!
      vo.reload.count_on_hand.should == 12
    end
  end
end
