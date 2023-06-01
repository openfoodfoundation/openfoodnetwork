# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe Spree::Order do
    let(:order) { build(:order) }

    context "#tax_zone" do
      let(:bill_address) { create :address }
      let(:ship_address) { create :address }
      let(:order) { Spree::Order.create(ship_address: ship_address, bill_address: bill_address) }
      let(:zone) { create :zone }

      context "when no zones exist" do
        before { Spree::Zone.destroy_all }

        it "should return nil" do
          expect(order.tax_zone).to be_nil
        end
      end

      context "when :tax_using_ship_address => true" do
        before { Spree::Config.set(tax_using_ship_address: true) }

        it "should calculate using ship_address" do
          expect(Spree::Zone).to receive(:match).at_least(:once).with(ship_address)
          expect(Spree::Zone).not_to receive(:match).with(bill_address)
          order.tax_zone
        end
      end

      context "when :tax_using_ship_address => false" do
        before { Spree::Config.set(tax_using_ship_address: false) }

        it "should calculate using bill_address" do
          expect(Spree::Zone).to receive(:match).at_least(:once).with(bill_address)
          expect(Spree::Zone).not_to receive(:match).with(ship_address)
          order.tax_zone
        end
      end

      context "when there is a default tax zone" do
        before do
          @default_zone = create(:zone, name: "foo_zone")
          allow(Spree::Zone).to receive_messages default_tax: @default_zone
        end

        context "when there is a matching zone" do
          before { allow(Spree::Zone).to receive_messages(match: zone) }

          it "should return the matching zone" do
            expect(order.tax_zone).to eq zone
          end
        end

        context "when there is no matching zone" do
          before { allow(Spree::Zone).to receive_messages(match: nil) }

          it "should return the default tax zone" do
            expect(order.tax_zone).to eq @default_zone
          end
        end
      end

      context "when no default tax zone" do
        before { allow(Spree::Zone).to receive_messages default_tax: nil }

        context "when there is a matching zone" do
          before { allow(Spree::Zone).to receive_messages(match: zone) }

          it "should return the matching zone" do
            expect(order.tax_zone).to eq zone
          end
        end

        context "when there is no matching zone" do
          before { allow(Spree::Zone).to receive_messages(match: nil) }

          it "should return nil" do
            expect(order.tax_zone).to be_nil
          end
        end
      end
    end

    context "#exclude_tax?" do
      before do
        @order = create(:order)
        @default_zone = create(:zone)
        allow(Spree::Zone).to receive_messages default_tax: @default_zone
      end

      context "when prices include tax" do
        before { Spree::Config.set(prices_inc_tax: true) }

        it "should be true when tax_zone is not the same as the default" do
          allow(@order).to receive_messages tax_zone: create(:zone, name: "other_zone")
          expect(@order.exclude_tax?).to be_truthy
        end

        it "should be false when tax_zone is the same as the default" do
          allow(@order).to receive_messages tax_zone: @default_zone
          expect(@order.exclude_tax?).to be_falsy
        end
      end

      context "when prices do not include tax" do
        before { Spree::Config.set(prices_inc_tax: false) }

        it "should be false" do
          expect(@order.exclude_tax?).to be_falsy
        end
      end
    end

    describe "#create_tax_charge!" do
      context "handling legacy taxes" do
        let(:order) { create(:order) }
        let(:zone) { create(:zone_with_member) }
        let(:tax_rate20) {
          create(:tax_rate, amount: 0.20, included_in_price: false, zone: zone)
        }
        let(:tax_rate30) {
          create(:tax_rate, amount: 0.30, included_in_price: false, zone: zone)
        }
        let!(:variant) {
          create(:variant, tax_category: tax_rate20.tax_category, price: 10)
        }
        let!(:line_item) {
          create(:line_item, variant: variant, order: order, quantity: 2)
        }
        let!(:shipping_method) {
          create(:shipping_method, tax_category: tax_rate30.tax_category)
        }
        let!(:shipment) {
          create(:shipment_with, :shipping_method, order: order, cost: 50,
                                                   shipping_method: shipping_method)
        }

        before do
          shipment.update_columns(cost: 20.0)
          order.reload

          allow(order).to receive(:completed_at) { Time.zone.now }
          allow(order).to receive(:tax_zone) { zone }
        end

        context "when the order has legacy taxes" do
          let!(:legacy_tax_adjustment) {
            create(:adjustment, order: order, adjustable: order, included: false,
                                label: "legacy", originator_type: "Spree::TaxRate")
          }

          before do
            order.update(state: "payment")
          end

          it "removes any legacy tax adjustments on order" do
            order.create_tax_charge!

            expect(order.reload.adjustments).to_not include legacy_tax_adjustment
          end

          it "re-applies taxes on individual items" do
            order.create_tax_charge!

            expect(order.all_adjustments.tax.count).to eq 2
            expect(line_item.adjustments.tax.first.amount).to eq 4
            expect(shipment.adjustments.tax.first.amount).to eq 6
          end
        end
      end
    end
  end
end
