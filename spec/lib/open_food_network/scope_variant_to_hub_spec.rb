# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/scope_variant_to_hub'

module OpenFoodNetwork
  describe ScopeVariantToHub do
    let(:hub) { create(:distributor_enterprise) }
    let(:v)   { create(:variant, price: 11.11, on_hand: 1, on_demand: true, sku: "VARIANTSKU") }
    let(:v2)  { create(:variant, price: 22.22, on_hand: 5) }
    let(:v3)  { create(:variant, price: 33.33, on_hand: 6) }
    let(:vo)  {
      create(:variant_override, hub: hub, variant: v, price: 22.22, count_on_hand: 2,
                                on_demand: false, sku: "VOSKU")
    }
    let(:vo2) {
      create(:variant_override, hub: hub, variant: v2, price: 33.33, count_on_hand: nil,
                                on_demand: true)
    }
    let(:vo3) { create(:variant_override, hub: hub, variant: v3, price: 44.44, count_on_hand: 16) }
    let(:vo_price_only) {
      create(:variant_override, :use_producer_stock_settings, hub: hub, variant: v, price: 22.22)
    }
    let(:scoper) { ScopeVariantToHub.new(hub) }

    describe "overriding price" do
      it "returns the overridden price when one is present" do
        vo
        scoper.scope v
        expect(v.price).to eq(22.22)
      end

      it "returns the variant's price otherwise" do
        scoper.scope v
        expect(v.price).to eq(11.11)
      end
    end

    describe "overriding price_in" do
      it "returns the overridden price when one is present" do
        vo
        scoper.scope v
        expect(v.price_in('AUD').amount).to eq(22.22)
      end

      it "returns the variant's price otherwise" do
        scoper.scope v
        expect(v.price_in('AUD').amount).to eq(11.11)
      end
    end

    describe "overriding stock levels" do
      it "returns the overridden stock level when one is present" do
        vo
        scoper.scope v
        expect(v.on_hand).to eq(2)
      end

      it "returns the variant's stock level otherwise" do
        scoper.scope v
        expect(v.on_hand).to eq(1)
      end

      describe "overriding stock on an on_demand variant" do
        let(:v) { create(:variant, price: 11.11, on_demand: true) }

        it "clears on_demand when the stock is overridden" do
          vo
          scoper.scope v
          expect(v.on_demand).to be false
        end

        it "does not clear on_demand when only the price is overridden" do
          vo_price_only
          scoper.scope v
          expect(v.on_demand).to be true
        end

        it "does not clear on_demand when there is no override" do
          scoper.scope v
          expect(v.on_demand).to be true
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

            context "when count_on_hand is not set" do
              before { vo.update_column(:count_on_hand, nil) }

              it "returns the variant's on_demand" do
                scoper.scope v
                expect(v.on_demand).to be true
              end
            end

            context "when count_on_hand is set" do
              it "should return validation error on save" do
                scoper.scope v
                expect{ vo.save! }.to raise_error ActiveRecord::RecordInvalid
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

      # in_stock? is indirectly overridden through can_supply?
      #   can_supply? is indirectly overridden by on_demand and total_on_hand
      #   these tests validate this chain is working correctly
      describe "overriding in_stock?" do
        before { v.on_demand = false }

        context "when an override exists" do
          before { vo }

          context "when variant in stock" do
            it "returns true if VO in stock" do
              scoper.scope v
              expect(v.in_stock?).to eq(true)
            end

            it "returns false if VO out of stock" do
              vo.update_attribute :count_on_hand, 0
              scoper.scope v
              expect(v.in_stock?).to eq(false)
            end
          end

          context "when variant out of stock" do
            before { v.on_hand = 0 }

            it "returns true if VO in stock" do
              scoper.scope v
              expect(v.in_stock?).to eq(true)
            end

            it "returns false if VO out of stock" do
              vo.update_attribute :count_on_hand, 0
              scoper.scope v
              expect(v.in_stock?).to eq(false)
            end
          end
        end

        context "when there's no override" do
          it "returns true if variant in stock" do
            scoper.scope v
            expect(v.in_stock?).to eq(true)
          end

          it "returns false if variant out of stock" do
            v.on_hand = 0
            scoper.scope v
            expect(v.in_stock?).to eq(false)
          end
        end
      end

      describe "overriding #move" do
        context "when override is on_demand" do
          before do
            vo2
            scoper.scope v2
          end

          it "doesn't reduce variant's stock" do
            v2.move(-2)
            expect(Spree::Variant.find(v2.id).on_hand).to eq 5
          end
        end

        context "when stock is overridden" do
          before do
            vo3
            scoper.scope v3
          end

          it "reduces the override's stock" do
            v3.move(-2)
            expect(vo3.reload.count_on_hand).to eq 14
          end

          it "doesn't reduce the variant's stock" do
            v3.move(-2)
            expect(Spree::Variant.find(v3.id).on_hand).to eq 6
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
