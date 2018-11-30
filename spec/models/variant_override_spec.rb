require 'spec_helper'

describe VariantOverride do
  let(:variant) { create(:variant) }
  let(:hub)     { create(:distributor_enterprise) }

  describe "scopes" do
    let(:hub1) { create(:distributor_enterprise) }
    let(:hub2) { create(:distributor_enterprise) }
    let!(:vo1) { create(:variant_override, hub: hub1, variant: variant, import_date: Time.zone.now.yesterday) }
    let!(:vo2) { create(:variant_override, hub: hub2, variant: variant, import_date: Time.zone.now) }
    let!(:vo3) { create(:variant_override, hub: hub1, variant: variant, permission_revoked_at: Time.now) }

    it "ignores variant_overrides with revoked_permissions by default" do
      expect(VariantOverride.all).to_not include vo3
      expect(VariantOverride.unscoped).to include vo3
    end

    it "finds variant overrides for a set of hubs" do
      VariantOverride.for_hubs([hub1, hub2]).should match_array [vo1, vo2]
    end

    it "fetches import dates for hubs in descending order" do
      import_dates = VariantOverride.distinct_import_dates.pluck :import_date

      expect(import_dates[0].to_i).to eq(vo2.import_date.to_i)
      expect(import_dates[1].to_i).to eq(vo1.import_date.to_i)
    end

    describe "fetching variant overrides indexed by variant" do
      it "gets indexed variant overrides for one hub" do
        VariantOverride.indexed(hub1).should == {variant => vo1}
        VariantOverride.indexed(hub2).should == {variant => vo2}
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

  describe "with price" do
    let(:variant_override) { create(:variant_override, variant: variant, hub: hub, price: 12.34) }

    it "returns the numeric price" do
      variant_override.price.should == 12.34
    end
  end

  describe "with nil count on hand" do
    let(:variant_override) { create(:variant_override, variant: variant, hub: hub, count_on_hand: nil) }

    describe "stock_overridden?" do
      it "returns false" do
        variant_override.stock_overridden?.should be false
      end
    end

    describe "move_stock!" do
      it "silently logs an error" do
        Bugsnag.should_receive(:notify)
        variant_override.move_stock!(5)
      end
    end
  end

  describe "with count on hand" do
    let(:variant_override) { create(:variant_override, variant: variant, hub: hub, count_on_hand: 12) }

    it "returns the numeric count on hand" do
      variant_override.count_on_hand.should == 12
    end

    describe "stock_overridden?" do
      it "returns true" do
        variant_override.stock_overridden?.should be true
      end
    end

    describe "move_stock!" do
      it "does nothing for quantity zero" do
        variant_override.move_stock! 0
        variant_override.reload.count_on_hand.should == 12
      end

      it "increments count_on_hand when quantity is negative" do
        variant_override.move_stock! 2
        variant_override.reload.count_on_hand.should == 14
      end

      it "decrements count_on_hand when quantity is negative" do
        variant_override.move_stock! -2
        variant_override.reload.count_on_hand.should == 10
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

  context "extends LocalizedNumber" do
    it_behaves_like "a model using the LocalizedNumber module", [:price]
  end
end
