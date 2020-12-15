# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe Adjustment do
    let(:order) { build(:order) }
    # This hack is included in the Spree specs, possibly for performance reasons:
    # before { allow_any_instance_of(Spree::Order).to receive(:update!) { nil } }
    let(:adjustment) { Spree::Adjustment.create(label: "Adjustment", amount: 5) }

    context "#update!" do
      # Regression test for Spree #6689
      it "correctly calculates for adjustments with no source" do
        expect(adjustment.update!).to eq 5
      end

      context "when adjustment is immutable" do
        before { adjustment.stub immutable?: true }

        it "does not update the adjustment" do
          adjustment.should_not_receive(:update_column)
          adjustment.update!
        end
      end

      context "when adjustment is mutable" do
        before { adjustment.stub immutable?: false }

        it "updates the amount" do
          adjustment.stub adjustable: double("Adjustable")
          adjustment.stub source: double("Source")
          adjustment.source.should_receive("compute_amount").with(adjustment.adjustable).and_return(5)
          adjustment.should_receive(:update_columns).with(amount: 5, updated_at: kind_of(Time))
          adjustment.update!
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

    describe "querying included tax" do
      # These specs need to e updated to reflect the new TaxRate#included boolean
      # and the general move towards included_tax, additional_tax, or no_tax.
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

    # In the Spree 2.2 specs, most of these tests related to applying a TaxRate to a LineItem are moved to
    # the TaxRate specs and aren't present here. The responsibility for this behavior is not in this class.
    # See core/spec/models/spree/tax_rate_spec.rb and core/spec/models/spree/adjustment_spec.rb

    describe "recording included and additional tax" do
      describe "TaxRate adjustments" do
        let!(:zone)        { create(:zone_with_member) }
        let!(:order)       { create(:order_with_line_items, line_items_count: 1, bill_address: create(:address)) }
        let(:tax_rate)     { create(:tax_rate, included_in_price: true, amount: 0.10) } # 10% rate
        let(:line_item) { order.line_items.first }
        let(:adjustment)   { line_item.adjustments(:reload).first }

        before do
          order.reload
          TaxRate.store_pre_tax_amount(line_item, [tax_rate])
          tax_rate.adjust(order, line_item)
        end

        context "when the tax rate is included" do
          it "has 10% inclusive tax correctly recorded" do
            amount = line_item.amount * tax_rate.amount / (1 + tax_rate.amount)
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
        let(:hub)             { create(:distributor_enterprise, charges_sales_tax: true) }
        let(:order)           { create(:order, distributor: hub) }
        let(:line_item)       { create(:line_item, order: order) }

        let(:shipping_method) { create(:shipping_method_with, :flat_rate) }
        let(:shipment)        { create(:shipment_with, :shipping_method, shipping_method: shipping_method, order: order) }

        describe "the shipping charge" do
          it "is the adjustment amount" do
            order.shipments = [shipment]
            expect(order.adjustments.first.amount).to eq(50)
          end
        end

        describe "when tax on shipping is disabled" do
          before do
            allow(Config).to receive(:shipment_inc_vat).and_return(false)
          end

          it "records 0% tax on shipment adjustments" do
            allow(Config).to receive(:shipping_tax_rate).and_return(0)
            order.shipments = [shipment]

            expect(order.adjustments.first.included_tax).to eq(0)
          end

          it "records 0% tax on shipments when a rate is set but shipment_inc_vat is false" do
            allow(Config).to receive(:shipping_tax_rate).and_return(0.25)
            order.shipments = [shipment]

            expect(order.adjustments.first.included_tax).to eq(0)
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
            expect(order.adjustments.first.included_tax).to eq(10.00)
          end

          it "records 0% tax on shipments when shipping_tax_rate is not set" do
            allow(Config).to receive(:shipping_tax_rate).and_return(0)
            order.shipments = [shipment]

            expect(order.adjustments.first.included_tax).to eq(0)
          end

          it "records 0% tax on shipments when the distributor does not charge sales tax" do
            order.distributor.update! charges_sales_tax: false
            order.shipments = [shipment]

            expect(order.adjustments.first.included_tax).to eq(0)
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
        let(:adjustment)  { order.adjustments(:reload).enterprise_fee.first }

        context "when enterprise fees have a fixed tax_category" do
          before do
            order.reload.update_distribution_charge!
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
                order.update_distribution_charge!
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
                order.update_distribution_charge!
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
                order.update_distribution_charge!
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
            order.update_distribution_charge!
          end

          context "when enterprise fees are taxed per-order" do
            let(:enterprise_fee) { create(:enterprise_fee, enterprise: coordinator, inherits_tax_category: true, calculator: ::Calculator::FlatRate.new(preferred_amount: 50.0)) }

            describe "when the tax rate includes the tax in the price" do
              it "records no tax on the enterprise fee adjustments" do
                # EnterpriseFee tax category is nil and inheritance only applies to per item fees
                # so tax on the enterprise_fee adjustment will be 0
                # Tax on line item is: 0.2/1.2 x $10 = $1.67
                expect(adjustment.included_tax).to eq(0.0)
                expect(line_item.adjustments.first.included_tax).to eq(1.67)
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                product_tax_rate.update_attribute :included_in_price, false
                order.reload.create_tax_charge! # Updating line_item or order has the same effect
                order.reload.update_distribution_charge!
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
                expect(line_item.adjustments.first.included_tax).to eq(1.67)
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                product_tax_rate.update_attribute :included_in_price, false
                order.reload.create_tax_charge! # Updating line_item or order has the same effect
                order.update_distribution_charge!
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
  end
end
