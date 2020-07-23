require 'spec_helper'

module Spree
  describe Adjustment do
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
        let(:tax_rate)     { create(:tax_rate, included_in_price: true, calculator: Calculator::FlatRate.new(preferred_amount: 0.1)) }
        let(:adjustment)   { line_item.adjustments(:reload).first }

        before do
          order.reload
          tax_rate.adjust(order)
        end

        it "has 100% tax included" do
          expect(adjustment.amount).to be > 0
          expect(adjustment.included_tax).to eq(adjustment.amount)
        end

        it "does not crash when order data has been updated previously" do
          order.price_adjustments.first.destroy
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
          let(:product_tax_rate)             { create(:tax_rate, included_in_price: true, calculator: ::Calculator::DefaultTax.new, zone: zone, amount: 0.2) }
          let(:product_tax_category)         { create(:tax_category, tax_rates: [product_tax_rate]) }

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
