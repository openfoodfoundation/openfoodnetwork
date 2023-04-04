# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe Adjustment do
    let(:order) { build(:order) }
    let(:adjustment) { Spree::Adjustment.create(label: "Adjustment", amount: 5) }

    describe "associations" do
      it { is_expected.to have_one(:metadata) }
      it { is_expected.to have_many(:adjustments) }

      it { is_expected.to belong_to(:adjustable) }

      it { is_expected.to belong_to(:adjustable) }
      it { is_expected.to belong_to(:originator) }
      it { is_expected.to belong_to(:order) }
      it { is_expected.to belong_to(:tax_category) }
      it { is_expected.to belong_to(:tax_rate) }
      it { is_expected.to belong_to(:voucher) }
    end

    describe "scopes" do
      let!(:arbitrary_adjustment) { create(:adjustment, label: "Arbitrary") }
      let!(:return_authorization_adjustment) {
        create(:adjustment, originator: create(:return_authorization))
      }

      it "returns return_authorization adjustments" do
        expect(Spree::Adjustment.return_authorization.to_a).to eq [return_authorization_adjustment]
      end
    end

    context "#update_adjustment!" do
      context "when originator present" do
        let(:originator) { instance_double(EnterpriseFee, compute_amount: 10.0) }
        let(:adjustable) { instance_double(LineItem) }

        before do
          allow(adjustment).to receive_messages originator: originator, label: 'adjustment',
                                                adjustable: adjustable, amount: 0
        end

        it "should do nothing when closed" do
          adjustment.close
          expect(originator).not_to receive(:compute_amount)
          adjustment.update_adjustment!
        end

        it "should do nothing when finalized" do
          adjustment.finalize
          expect(originator).not_to receive(:compute_amount)
          adjustment.update_adjustment!
        end

        it "should ask the originator to recalculate the amount" do
          expect(originator).to receive(:compute_amount)
          adjustment.update_adjustment!
        end

        context "using the :force argument" do
          it "should update adjustments without changing their state" do
            expect(originator).to receive(:compute_amount)
            adjustment.update_adjustment!(force: true)
            expect(adjustment.state).to eq "open"
          end

          it "should update closed adjustments" do
            adjustment.close
            expect(originator).to receive(:compute_amount)
            adjustment.update_adjustment!(force: true)
          end
        end
      end

      it "should do nothing when originator is nil" do
        allow(adjustment).to receive_messages originator: nil
        expect(adjustment).not_to receive(:update_columns)
        adjustment.update_adjustment!
      end

      context "where the adjustable has been deleted" do
        let(:line_item) { create(:line_item, price: 10) }
        let!(:adjustment) { create(:adjustment, adjustable: line_item) }

        it "returns zero" do
          line_item.delete
          expect(adjustment.reload.update_adjustment!).to eq 0.0
        end

        it "removes orphaned adjustments" do
          expect {
            line_item.delete
            adjustment.reload.update_adjustment!
          }.to change{ Spree::Adjustment.count }.by(-1)
        end
      end
    end

    context "adjustment state" do
      let(:adjustment) { create(:adjustment, state: 'open') }

      context "#immutable?" do
        it "is true when adjustment state isn't open" do
          adjustment.state = "closed"
          expect(adjustment).to be_immutable
          adjustment.state = "finalized"
          expect(adjustment).to be_immutable
        end

        it "is false when adjustment state is open" do
          adjustment.state = "open"
          expect(adjustment).to_not be_immutable
        end
      end

      context "#finalized?" do
        it "is true when adjustment state is finalized" do
          adjustment.state = "finalized"
          expect(adjustment).to be_finalized
        end

        it "is false when adjustment state isn't finalized" do
          adjustment.state = "closed"
          expect(adjustment).to_not be_finalized
          adjustment.state = "open"
          expect(adjustment).to_not be_finalized
        end
      end
    end

    context "#display_amount" do
      before { adjustment.amount = 10.55 }

      context "with display_currency set to true" do
        before { Spree::Config[:display_currency] = true }

        it "shows the currency" do
          expect(adjustment.display_amount.to_s).to eq "$10.55 #{Spree::Config[:currency]}"
        end
      end

      context "with display_currency set to false" do
        before { Spree::Config[:display_currency] = false }

        it "does not include the currency" do
          expect(adjustment.display_amount.to_s).to eq "$10.55"
        end
      end

      context "with currency set to JPY" do
        context "when adjustable is set to an order" do
          before do
            allow(order).to receive(:currency) { 'JPY' }
            adjustment.adjustable = order
          end

          it "displays in JPY" do
            expect(adjustment.display_amount.to_s).to eq "¥11"
          end
        end

        context "when adjustable is nil" do
          it "displays in the default currency" do
            expect(adjustment.display_amount.to_s).to eq "$10.55"
          end
        end
      end
    end

    context '#currency' do
      it 'returns the globally configured currency' do
        expect(adjustment.currency).to eq Spree::Config[:currency]
      end
    end

    it "has metadata" do
      adjustment = create(:adjustment, metadata: create(:adjustment_metadata))
      expect(adjustment.metadata).to be
    end

    describe "recording included tax" do
      describe "TaxRate adjustments" do
        let!(:zone)        { create(:zone_with_member) }
        let!(:order)       { create(:order, bill_address: create(:address)) }
        let!(:line_item)   { create(:line_item, order: order) }
        let(:tax_category) { create(:tax_category, tax_rates: [tax_rate]) }
        let(:tax_rate)     { create(:tax_rate, included_in_price: true, amount: 0.10) }
        let(:adjustment)   { line_item.adjustments.reload.first }

        before do
          order.reload
          tax_rate.adjust(order, line_item)
        end

        context "when the tax rate is inclusive" do
          it "has 10% inclusive tax correctly recorded" do
            amount = line_item.amount - (line_item.amount / (1 + tax_rate.amount))
            rounded_amount = tax_rate.calculator.__send__(:round_to_two_places, amount)
            expect(adjustment.amount).to eq rounded_amount
            expect(adjustment.amount).to eq 0.91
            expect(adjustment.included).to be true
          end

          it "does not crash when order data has been updated previously" do
            order.line_item_adjustments.first.destroy
            tax_rate.adjust(order, line_item)
          end
        end

        context "when the tax rate is additional" do
          let(:tax_rate) { create(:tax_rate, included_in_price: false, amount: 0.10) }

          it "has 10% added tax correctly recorded" do
            expect(adjustment.amount).to eq line_item.amount * tax_rate.amount
            expect(adjustment.amount).to eq 1.0
            expect(adjustment.included).to be false
          end
        end
      end

      describe "Shipment adjustments" do
        let(:zone) { create(:zone_with_member) }
        let(:inclusive_tax) { true }
        let(:tax_rate) {
          create(:tax_rate, included_in_price: inclusive_tax, zone: zone, amount: 0.25)
        }
        let(:tax_category)    { create(:tax_category, name: "Shipping", tax_rates: [tax_rate] ) }
        let(:hub)             { create(:distributor_enterprise, charges_sales_tax: true) }
        let(:order)           { create(:order, distributor: hub) }
        let(:line_item)       { create(:line_item, order: order) }

        let(:shipping_method) {
          create(:shipping_method_with, :flat_rate, tax_category: tax_category)
        }
        let(:shipment) {
          create(:shipment_with, :shipping_method, shipping_method: shipping_method, order: order)
        }

        describe "the shipping charge" do
          it "is the adjustment amount" do
            order.shipments = [shipment]
            expect(order.shipment_adjustments.first.amount).to eq(50)
            expect(shipment.cost).to eq(50)
          end
        end

        context "with tax" do
          before do
            allow(order).to receive(:tax_zone) { zone }
          end

          context "when the shipment has an inclusive tax rate" do
            it "calculates the shipment tax from the tax rate" do
              order.shipments = [shipment]
              order.create_tax_charge!
              order.update_totals

              # Finding the tax included in an amount that's already inclusive of tax:
              # total - ( total / (1 + rate) )
              # 50    - ( 50    / (1 + 0.25) )
              # = 10
              expect(order.shipment_adjustments.tax.first.amount).to eq(10)
              expect(order.shipment_adjustments.tax.first.included).to eq true

              expect(shipment.reload.cost).to eq(50)
              expect(shipment.included_tax_total).to eq(10)
              expect(shipment.additional_tax_total).to eq(0)

              expect(order.included_tax_total).to eq(10)
              expect(order.additional_tax_total).to eq(0)
            end
          end

          context "when the shipment has an added tax rate" do
            let(:inclusive_tax) { false }

            it "records the tax on the shipment's adjustments" do
              order.shipments = [shipment]
              order.create_tax_charge!
              order.update_totals

              # Finding the added tax for an amount:
              # total * rate
              # 50    * 0.25
              # = 12.5
              expect(order.shipment_adjustments.tax.first.amount).to eq(12.50)
              expect(order.shipment_adjustments.tax.first.included).to eq false

              expect(shipment.reload.cost).to eq(50)
              expect(shipment.included_tax_total).to eq(0)
              expect(shipment.additional_tax_total).to eq(12.50)

              expect(order.included_tax_total).to eq(0)
              expect(order.additional_tax_total).to eq(12.50)
            end
          end

          context "when the distributor does not charge sales tax" do
            it "records 0% tax on shipments" do
              order.distributor.update! charges_sales_tax: false
              order.shipments = [shipment]
              order.create_tax_charge!
              order.update_totals

              expect(order.shipment_adjustments.tax.count).to be_zero

              expect(shipment.reload.cost).to eq(50)
              expect(shipment.included_tax_total).to eq(0)
              expect(shipment.additional_tax_total).to eq(0)

              expect(order.included_tax_total).to eq(0)
              expect(order.additional_tax_total).to eq(0)
            end
          end

          context "when the shipment has no applicable tax rate" do
            it "records 0% tax on shipments" do
              allow(shipment).to receive(:tax_category) { nil }
              order.shipments = [shipment]
              order.create_tax_charge!
              order.update_totals

              expect(order.shipment_adjustments.tax.count).to be_zero

              expect(shipment.reload.cost).to eq(50)
              expect(shipment.included_tax_total).to eq(0)
              expect(shipment.additional_tax_total).to eq(0)

              expect(order.included_tax_total).to eq(0)
              expect(order.additional_tax_total).to eq(0)
            end
          end
        end
      end

      describe "EnterpriseFee adjustments" do
        let(:zone)             { create(:zone_with_member) }
        let(:fee_tax_rate)     {
          create(:tax_rate, included_in_price: true, calculator: ::Calculator::DefaultTax.new, zone: zone,
                            amount: 0.1)
        }
        let(:fee_tax_category) { create(:tax_category, tax_rates: [fee_tax_rate]) }

        let(:coordinator) { create(:distributor_enterprise, charges_sales_tax: true) }
        let(:variant)     { create(:variant, product: create(:product, tax_category: nil)) }
        let(:order_cycle) {
          create(:simple_order_cycle, coordinator: coordinator, coordinator_fees: [enterprise_fee],
                                      distributors: [coordinator], variants: [variant])
        }
        let(:line_item)   { create(:line_item, variant: variant) }
        let(:order)       {
          create(:order, line_items: [line_item], order_cycle: order_cycle,
                         distributor: coordinator)
        }
        let(:fee)         { order.all_adjustments.reload.enterprise_fee.first }
        let(:fee_tax)     { fee.adjustments.tax.first }

        context "when enterprise fees have a fixed tax_category" do
          before do
            order.recreate_all_fees!
          end

          context "when enterprise fees are taxed per-order" do
            let(:enterprise_fee) {
              create(:enterprise_fee, enterprise: coordinator, tax_category: fee_tax_category,
                                      calculator: ::Calculator::FlatRate.new(preferred_amount: 50.0))
            }

            describe "when the tax rate includes the tax in the price" do
              it "records the correct amount in a tax adjustment" do
                # The fee is $50, tax is 10%, and the fee is inclusive of tax
                # Therefore, the included tax should be 0.1/1.1 * 50 = $4.55

                expect(fee_tax.amount).to eq(4.55)
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                fee_tax_rate.update_attribute :included_in_price, false
                order.recreate_all_fees!
              end

              it "records the correct amount in a tax adjustment" do
                expect(fee_tax.amount).to eq(5.0)
              end
            end

            describe "when enterprise fees have no tax" do
              before do
                enterprise_fee.tax_category = nil
                enterprise_fee.save!
                order.recreate_all_fees!
              end

              it "records no tax as charged" do
                expect(fee_tax).to be_nil
              end
            end
          end

          context "when enterprise fees are taxed per-item" do
            let(:enterprise_fee) {
              create(:enterprise_fee, enterprise: coordinator, tax_category: fee_tax_category,
                                      calculator: ::Calculator::PerItem.new(preferred_amount: 50.0))
            }

            describe "when the tax rate includes the tax in the price" do
              it "records the correct amount in a tax adjustment" do
                expect(fee_tax.amount).to eq(4.55)
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                fee_tax_rate.update_attribute :included_in_price, false
                order.recreate_all_fees!
              end

              it "records the correct amount in a tax adjustment" do
                expect(fee_tax.amount).to eq(5.0)
              end
            end
          end
        end

        context "when enterprise fees inherit their tax_category from the product they are applied to" do
          let(:product_tax_rate) {
            create(:tax_rate, included_in_price: true, calculator: ::Calculator::DefaultTax.new,
                              zone: zone, amount: 0.2)
          }
          let(:product_tax_category) { create(:tax_category, tax_rates: [product_tax_rate]) }

          before do
            variant.product.update_attribute(:tax_category_id, product_tax_category.id)
            order.recreate_all_fees!
          end

          context "when enterprise fees are taxed per-order" do
            let(:enterprise_fee) {
              create(:enterprise_fee, enterprise: coordinator, inherits_tax_category: true,
                                      calculator: ::Calculator::FlatRate.new(preferred_amount: 50.0))
            }

            describe "when the tax rate includes the tax in the price" do
              it "records no tax on the enterprise fee adjustments" do
                # EnterpriseFee tax category is nil and inheritance only applies to per item fees
                # so tax on the enterprise_fee adjustment will be 0
                # Tax on line item is: 0.2/1.2 x $10 = $1.67
                expect(fee_tax).to be_nil
                expect(line_item.adjustments.tax.first.amount).to eq(1.67)
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                product_tax_rate.update_attribute :included_in_price, false
                order.reload.recreate_all_fees!
              end

              it "records the no tax on TaxRate adjustment on the order" do
                # EnterpriseFee tax category is nil and inheritance only applies to per item fees
                # so total tax on the order is only that which applies to the line_item itself
                # ie. $10 x 0.2 = $2.0
                expect(fee_tax).to be_nil
              end
            end
          end

          context "when enterprise fees are taxed per-item" do
            let(:enterprise_fee) {
              create(:enterprise_fee, enterprise: coordinator, inherits_tax_category: true,
                                      calculator: ::Calculator::PerItem.new(preferred_amount: 50.0))
            }

            describe "when the tax rate includes the tax in the price" do
              it "records the correct amount in a tax adjustment" do
                # Applying product tax rate of 0.2 to enterprise fee of $50
                # gives tax on fee of 0.2/1.2 x $50 = $8.33
                # Tax on line item is: 0.2/1.2 x $10 = $1.67
                expect(fee_tax.amount).to eq(8.33)
                expect(line_item.adjustments.tax.first.amount).to eq(1.67)
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                product_tax_rate.update_attribute :included_in_price, false
                order.recreate_all_fees!
              end

              it "records the correct amount in a tax adjustment" do
                # EnterpriseFee inherits tax_category from product so total tax on
                # the order is that which applies to the line item itself, plus the
                # same rate applied to the fee of $50. ie. ($10 + $50) x 0.2 = $12.0
                expect(fee_tax.amount).to eq(10.0)
                expect(order.all_adjustments.tax.sum(:amount)).to eq(12.0)
              end
            end
          end
        end
      end
    end

    context "extends LocalizedNumber" do
      it_behaves_like "a model using the LocalizedNumber module", [:amount]
    end

    describe "inclusive and additional taxes" do
      let!(:zone) { create(:zone_with_member) }
      let!(:tax_category) { create(:tax_category, name: "Tax Test") }
      let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
      let(:order) { create(:order, distributor: distributor) }
      let(:included_in_price) { true }
      let(:tax_rate) {
        create(:tax_rate, included_in_price: included_in_price, zone: zone,
                          calculator: ::Calculator::FlatRate.new(preferred_amount: 0.1))
      }
      let(:product) { create(:product, tax_category: tax_category) }
      let(:variant) { product.variants.first }

      describe "tax adjustment creation" do
        before do
          tax_category.tax_rates << tax_rate
          allow(order).to receive(:tax_zone) { zone }
          order.line_items << create(:line_item, variant: variant, quantity: 5)
        end

        context "with included taxes" do
          it "records the tax as included" do
            expect(order.all_adjustments.tax.count).to eq 1
            expect(order.all_adjustments.tax.first.included).to be true
          end
        end

        context "with additional taxes" do
          let(:included_in_price) { false }

          it "records the tax as additional" do
            expect(order.all_adjustments.tax.count).to eq 1
            expect(order.all_adjustments.tax.first.included).to be false
          end
        end
      end

      describe "inclusive and additional scopes" do
        let(:included) { true }
        let(:adjustment) {
          create(:adjustment, adjustable: order, originator: tax_rate, included: included)
        }

        context "when tax is included in price" do
          it "is returned by the #included scope" do
            expect(Spree::Adjustment.inclusive).to eq [adjustment]
          end
        end

        context "when tax is additional to the price" do
          let(:included) { false }

          it "is returned by the #additional scope" do
            expect(Spree::Adjustment.additional).to eq [adjustment]
          end
        end
      end
    end

    context "return authorization adjustments" do
      let!(:return_authorization) { create(:return_authorization, amount: 123) }
      let(:order) { return_authorization.order }
      let!(:return_adjustment) {
        create(:adjustment, originator: return_authorization, order: order,
                            adjustable: order, amount: 456)
      }

      describe "#update_adjustment!" do
        it "sets a negative value equal to the return authorization amount" do
          expect { return_adjustment.update_adjustment! }.
            to change { return_adjustment.reload.amount }.to(-123)
        end
      end
    end
  end
end
