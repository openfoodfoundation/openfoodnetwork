require 'open_food_network/scope_variant_to_hub'

module OpenFoodNetwork
  describe ScopeVariantToHub do
    let(:hub) { create(:distributor_enterprise) }
    let(:v)   { create(:variant, price: 11.11, count_on_hand: 1, on_demand: true, sku: "VARIANTSKU") }
    let(:vo)  { create(:variant_override, hub: hub, variant: v, price: 22.22, count_on_hand: 2, on_demand: false, sku: "VOSKU") }
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
          v.on_demand.should be false
        end

        it "does not clear on_demand when only the price is overridden" do
          vo_price_only
          scoper.scope v
          v.on_demand.should be true
        end

        it "does not clear on_demand when there is no override" do
          scoper.scope v
          v.on_demand.should be true
        end
      end

      describe "overriding on_demand" do
        context "when an override exists" do
          before { vo }

          context "with an on_demand set" do
            it "returns the overridden on_demand" do
              scoper.scope v
              expect(v.on_demand).to be false
            end
          end

          context "without an on_demand set" do
            before { vo.update_column(:on_demand, nil) }

            context "when count_on_hand is set" do
              it "returns false" do
                scoper.scope v
                expect(v.on_demand).to be false
              end
            end

            context "when count_on_hand is not set" do
              before { vo.update_column(:count_on_hand, nil) }

              it "returns the variant's on_demand" do
                scoper.scope v
                expect(v.on_demand).to be true
              end
            end
          end
        end

        context "when no override exists" do
          it "returns the variant's on_demand" do
            scoper.scope v
            expect(v.on_demand).to be true
          end
        end
      end

      describe "overriding sku" do
        context "when an override exists" do
          before { vo }

          context "with an sku set" do
            it "returns the overridden sku" do
              scoper.scope v
              expect(v.sku).to eq "VOSKU"
            end
          end

          context "without an sku set" do
            before { vo.update_column(:sku, nil) }

            it "returns the variant's sku" do
              scoper.scope v
              expect(v.sku).to eq "VARIANTSKU"
            end
          end
        end

        context "when no override exists" do
          it "returns the variant's sku" do
            scoper.scope v
            expect(v.sku).to eq "VARIANTSKU"
          end
        end
      end
    end
  end
end
