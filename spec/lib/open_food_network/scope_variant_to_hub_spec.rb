require 'open_food_network/scope_variant_to_hub'

module OpenFoodNetwork
  describe ScopeVariantToHub do
    let(:hub) { create(:distributor_enterprise) }
    let(:v)   { create(:variant, price: 11.11, count_on_hand: 1) }
    let(:vo)  { create(:variant_override, hub: hub, variant: v, price: 22.22, count_on_hand: 2) }
    let(:vo_price_only) { create(:variant_override, hub: hub, variant: v, price: 22.22, count_on_hand: nil) }
    let(:scoper) { ScopeVariantToHub.new(hub) }

    describe "overriding price" do
      it "returns the overridden price when one is present" do
        vo
        scoper.scope v
        v.price.should == 22.22
      end

      it "returns the variant's price otherwise" do
        scoper.scope v
        v.price.should == 11.11
      end
    end

    describe "overriding price_in" do
      it "returns the overridden price when one is present" do
        vo
        scoper.scope v
        v.price_in('AUD').amount.should == 22.22
      end

      it "returns the variant's price otherwise" do
        scoper.scope v
        v.price_in('AUD').amount.should == 11.11
      end
    end

    describe "overriding stock levels" do
      it "returns the overridden stock level when one is present" do
        vo
        scoper.scope v
        v.count_on_hand.should == 2
      end

      it "returns the variant's stock level otherwise" do
        scoper.scope v
        v.count_on_hand.should == 1
      end

      describe "overriding stock on an on_demand variant" do
        let(:v) { create(:variant, price: 11.11, on_demand: true) }

        it "clears on_demand when the stock is overridden" do
          vo
          scoper.scope v
          v.on_demand.should be_false
        end

        it "does not clear on_demand when only the price is overridden" do
          vo_price_only
          scoper.scope v
          v.on_demand.should be_true
        end

        it "does not clear on_demand when there is no override" do
          scoper.scope v
          v.on_demand.should be_true
        end
      end
    end
  end
end
