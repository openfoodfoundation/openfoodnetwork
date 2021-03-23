# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe Adjustment do
    let(:order) { build(:order) }
    let(:adjustment) { Spree::Adjustment.create(label: "Adjustment", amount: 5) }

    describe "scopes" do
      let!(:arbitrary_adjustment) { create(:adjustment, source: nil, label: "Arbitrary") }
      let!(:return_authorization_adjustment) { create(:adjustment, source: create(:return_authorization)) }

      it "returns return_authorization adjustments" do
        expect(Spree::Adjustment.return_authorization.to_a).to eq [return_authorization_adjustment]
      end
    end

    context "#update!" do
      context "when originator present" do
        let(:originator) { double("originator", update_adjustment: nil) }
        before do
          allow(originator).to receive_messages update_amount: true
          allow(adjustment).to receive_messages originator: originator, label: 'adjustment', amount: 0
        end

        it "should do nothing when closed" do
          adjustment.close
          expect(originator).not_to receive(:update_adjustment)
          adjustment.update!
        end

        it "should do nothing when finalized" do
          adjustment.finalize
          expect(originator).not_to receive(:update_adjustment)
          adjustment.update!
        end

        it "should ask the originator to update_adjustment" do
          expect(originator).to receive(:update_adjustment)
          adjustment.update!
        end

        context "using the :force argument" do
          it "should update adjustments without changing their state" do
            expect(originator).to receive(:update_adjustment)
            adjustment.update!(force: true)
            expect(adjustment.state).to eq "open"
          end

          it "should update closed adjustments" do
            adjustment.close
            expect(originator).to receive(:update_adjustment)
            adjustment.update!(force: true)
          end
        end
      end

      it "should do nothing when originator is nil" do
        allow(adjustment).to receive_messages originator: nil
        expect(adjustment).not_to receive(:amount=)
        adjustment.update!
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

    describe "querying included tax" do
      let!(:adjustment_with_tax) { create(:adjustment, included_tax: 123) }
      let!(:adjustment_without_tax) { create(:adjustment, included_tax: 0) }

      describe "finding adjustments with and without tax included" do
        it "finds adjustments with tax" do
          expect(Adjustment.with_tax).to     include adjustment_with_tax
          expect(Adjustment.with_tax).not_to include adjustment_without_tax
        end

        it "finds adjustments without tax" do
          expect(Adjustment.without_tax).to     include adjustment_without_tax
          expect(Adjustment.without_tax).not_to include adjustment_with_tax
        end
      end

      describe "checking if an adjustment includes tax" do
        it "returns true when it has > 0 tax" do
          expect(adjustment_with_tax).to have_tax
        end

        it "returns false when it has 0 tax" do
          expect(adjustment_without_tax).not_to have_tax
        end
      end
    end

    describe "recording included tax" do
      describe "TaxRate adjustments" do
        let!(:zone)        { create(:zone_with_member) }
        let!(:order)       { create(:order, bill_address: create(:address)) }
        let!(:line_item)   { create(:line_item, order: order) }
        let(:tax_rate)     { create(:tax_rate, included_in_price: true, calculator: ::Calculator::FlatRate.new(preferred_amount: 0.1)) }
        let(:adjustment)   { line_item.adjustments.reload.first }

        before do
          order.reload
          tax_rate.adjust(order)
        end

        it "has tax included" do
          expect(adjustment.amount).to be > 0
          expect(adjustment.included).to be true
        end

        it "does not crash when order data has been updated previously" do
          order.line_item_adjustments.first.destroy
          tax_rate.adjust(order)
        end
      end

      describe "Shipment adjustments" do
        let(:hub)             { create(:distributor_enterprise, charges_sales_tax: true) }
        let(:order)           { create(:order, distributor: hub) }
        let(:line_item)       { create(:line_item, order: order) }

        let(:shipping_method) { create(:shipping_method_with, :flat_rate) }
        let(:shipment)        { create(:shipment_with, :shipping_method, shipping_method: shipping_method, order: order) }

        describe "the shipping charge" do
          it "is the adjustment amount" do
            order.shipments = [shipment]
            expect(order.shipment_adjustments.first.amount).to eq(50)
            expect(shipment.cost).to eq(50)
          end
        end

        describe "when tax on shipping is disabled" do
          before do
            allow(Config).to receive(:shipment_inc_vat).and_return(false)
          end

          it "records 0% tax on shipment adjustments" do
            allow(Config).to receive(:shipping_tax_rate).and_return(0)
            order.shipments = [shipment]

            expect(order.shipment_adjustments.first.included_tax).to eq(0)
          end

          it "records 0% tax on shipments when a rate is set but shipment_inc_vat is false" do
            allow(Config).to receive(:shipping_tax_rate).and_return(0.25)
            order.shipments = [shipment]

            expect(order.shipment_adjustments.first.included_tax).to eq(0)
          end
        end

        describe "when tax on shipping is enabled" do
          before do
            allow(Config).to receive(:shipment_inc_vat).and_return(true)
          end

          it "takes the shipment adjustment tax included from the system setting" do
            allow(Config).to receive(:shipping_tax_rate).and_return(0.25)
            order.shipments = [shipment]

            # Finding the tax included in an amount that's already inclusive of tax:
            # total - ( total / (1 + rate) )
            # 50    - ( 50    / (1 + 0.25) )
            # = 10
            expect(order.shipment_adjustments.first.included_tax).to eq(10.00)
          end

          it "records 0% tax on shipments when shipping_tax_rate is not set" do
            allow(Config).to receive(:shipping_tax_rate).and_return(0)
            order.shipments = [shipment]

            expect(order.shipment_adjustments.first.included_tax).to eq(0)
          end

          it "records 0% tax on shipments when the distributor does not charge sales tax" do
            order.distributor.update! charges_sales_tax: false
            order.shipments = [shipment]

            expect(order.shipment_adjustments.first.included_tax).to eq(0)
          end
        end
      end

      describe "EnterpriseFee adjustments" do
        let(:zone)             { create(:zone_with_member) }
        let(:fee_tax_rate)     { create(:tax_rate, included_in_price: true, calculator: ::Calculator::DefaultTax.new, zone: zone, amount: 0.1) }
        let(:fee_tax_category) { create(:tax_category, tax_rates: [fee_tax_rate]) }

        let(:coordinator) { create(:distributor_enterprise, charges_sales_tax: true) }
        let(:variant)     { create(:variant, product: create(:product, tax_category: nil)) }
        let(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator, coordinator_fees: [enterprise_fee], distributors: [coordinator], variants: [variant]) }
        let(:line_item)   { create(:line_item, variant: variant) }
        let(:order)       { create(:order, line_items: [line_item], order_cycle: order_cycle, distributor: coordinator) }
        let(:adjustment)  { order.all_adjustments.reload.enterprise_fee.first }

        context "when enterprise fees have a fixed tax_category" do
          before do
            order.reload.recreate_all_fees!
          end

          context "when enterprise fees are taxed per-order" do
            let(:enterprise_fee) { create(:enterprise_fee, enterprise: coordinator, tax_category: fee_tax_category, calculator: ::Calculator::FlatRate.new(preferred_amount: 50.0)) }

            describe "when the tax rate includes the tax in the price" do
              it "records the tax on the enterprise fee adjustments" do
                # The fee is $50, tax is 10%, and the fee is inclusive of tax
                # Therefore, the included tax should be 0.1/1.1 * 50 = $4.55

                expect(adjustment.included_tax).to eq(4.55)
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                fee_tax_rate.update_attribute :included_in_price, false
                order.reload.create_tax_charge! # Updating line_item or order has the same effect
                order.recreate_all_fees!
              end

              it "records the tax on TaxRate adjustment on the order" do
                expect(adjustment.included_tax).to eq(0)
                expect(order.adjustments.tax.first.amount).to eq(5.0)
              end
            end

            describe "when enterprise fees have no tax" do
              before do
                enterprise_fee.tax_category = nil
                enterprise_fee.save!
                order.recreate_all_fees!
              end

              it "records no tax as charged" do
                expect(adjustment.included_tax).to eq(0)
              end
            end
          end

          context "when enterprise fees are taxed per-item" do
            let(:enterprise_fee) { create(:enterprise_fee, enterprise: coordinator, tax_category: fee_tax_category, calculator: ::Calculator::PerItem.new(preferred_amount: 50.0)) }

            describe "when the tax rate includes the tax in the price" do
              it "records the tax on the enterprise fee adjustments" do
                expect(adjustment.included_tax).to eq(4.55)
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                fee_tax_rate.update_attribute :included_in_price, false
                order.reload.create_tax_charge! # Updating line_item or order has the same effect
                order.recreate_all_fees!
              end

              it "records the tax on TaxRate adjustment on the order" do
                expect(adjustment.included_tax).to eq(0)
                expect(order.adjustments.tax.first.amount).to eq(5.0)
              end
            end
          end
        end

        context "when enterprise fees inherit their tax_category from the product they are applied to" do
          let(:product_tax_rate) {
            create(:tax_rate, included_in_price: true, calculator: ::Calculator::DefaultTax.new, zone: zone, amount: 0.2)
          }
          let(:product_tax_category) { create(:tax_category, tax_rates: [product_tax_rate]) }

          before do
            variant.product.update_attribute(:tax_category_id, product_tax_category.id)

            order.create_tax_charge! # Updating line_item or order has the same effect
            order.recreate_all_fees!
          end

          context "when enterprise fees are taxed per-order" do
            let(:enterprise_fee) { create(:enterprise_fee, enterprise: coordinator, inherits_tax_category: true, calculator: ::Calculator::FlatRate.new(preferred_amount: 50.0)) }

            describe "when the tax rate includes the tax in the price" do
              it "records no tax on the enterprise fee adjustments" do
                # EnterpriseFee tax category is nil and inheritance only applies to per item fees
                # so tax on the enterprise_fee adjustment will be 0
                # Tax on line item is: 0.2/1.2 x $10 = $1.67
                expect(adjustment.included_tax).to eq(0.0)
                expect(line_item.adjustments.tax.first.amount).to eq(1.67)
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                product_tax_rate.update_attribute :included_in_price, false
                order.reload.create_tax_charge! # Updating line_item or order has the same effect
                order.reload.recreate_all_fees!
              end

              it "records the no tax on TaxRate adjustment on the order" do
                # EnterpriseFee tax category is nil and inheritance only applies to per item fees
                # so total tax on the order is only that which applies to the line_item itself
                # ie. $10 x 0.2 = $2.0
                expect(adjustment.included_tax).to eq(0)
                expect(order.adjustments.tax.first.amount).to eq(2.0)
              end
            end
          end

          context "when enterprise fees are taxed per-item" do
            let(:enterprise_fee) { create(:enterprise_fee, enterprise: coordinator, inherits_tax_category: true, calculator: ::Calculator::PerItem.new(preferred_amount: 50.0)) }

            describe "when the tax rate includes the tax in the price" do
              it "records the tax on the enterprise fee adjustments" do
                # Applying product tax rate of 0.2 to enterprise fee of $50
                # gives tax on fee of 0.2/1.2 x $50 = $8.33
                # Tax on line item is: 0.2/1.2 x $10 = $1.67
                expect(adjustment.included_tax).to eq(8.33)
                expect(line_item.adjustments.tax.first.amount).to eq(1.67)
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                product_tax_rate.update_attribute :included_in_price, false
                order.reload.create_tax_charge! # Updating line_item or order has the same effect
                order.recreate_all_fees!
              end

              it "records the tax on TaxRate adjustment on the order" do
                # EnterpriseFee inherits tax_category from product so total tax on
                # the order is that which applies to the line item itself, plus the
                # same rate applied to the fee of $50. ie. ($10 + $50) x 0.2 = $12.0
                expect(adjustment.included_tax).to eq(0)
                expect(order.adjustments.tax.first.amount).to eq(12.0)
              end
            end
          end
        end
      end

      describe "setting the included tax by tax rate" do
        let(:adjustment) { Adjustment.new label: 'foo', amount: 50 }

        it "sets it, rounding to two decimal places" do
          adjustment.set_included_tax! 0.25
          expect(adjustment.included_tax).to eq(10.00)
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
          create(:adjustment, adjustable: order, source: order,
                 originator: tax_rate, included: included)
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
  end
end
