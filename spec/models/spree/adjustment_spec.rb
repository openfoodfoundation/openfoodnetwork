module Spree
  describe Adjustment do
    it "has metadata" do
      adjustment = create(:adjustment, metadata: create(:adjustment_metadata))
      adjustment.metadata.should be
    end

    describe "querying included tax" do
      let!(:adjustment_with_tax) { create(:adjustment, included_tax: 123) }
      let!(:adjustment_without_tax) { create(:adjustment, included_tax: 0) }

      describe "finding adjustments with and without tax included" do
        it "finds adjustments with tax" do
          Adjustment.with_tax.should     include adjustment_with_tax
          Adjustment.with_tax.should_not include adjustment_without_tax
        end

        it "finds adjustments without tax" do
          Adjustment.without_tax.should     include adjustment_without_tax
          Adjustment.without_tax.should_not include adjustment_with_tax
        end
      end

      describe "checking if an adjustment includes tax" do
        it "returns true when it has > 0 tax" do
          adjustment_with_tax.should have_tax
        end

        it "returns false when it has 0 tax" do
          adjustment_without_tax.should_not have_tax
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
          adjustment.amount.should be > 0
          adjustment.included_tax.should == adjustment.amount
        end

        it "does not crash when order data has been updated previously" do
          order.price_adjustments.first.destroy
          tax_rate.adjust(order)
        end
      end

      describe "Shipment adjustments" do
        let!(:order)          { create(:order, distributor: hub, shipping_method: shipping_method) }
        let(:hub)             { create(:distributor_enterprise, charges_sales_tax: true) }
        let!(:line_item)      { create(:line_item, order: order) }
        let(:shipping_method) { create(:shipping_method, calculator: Calculator::FlatRate.new(preferred_amount: 50.0)) }
        let(:adjustment)      { order.adjustments(:reload).shipping.first }

        it "has a shipping charge of $50" do
          order.create_shipment!
          adjustment.amount.should == 50
        end

        describe "when tax on shipping is disabled" do
          it "records 0% tax on shipment adjustments" do
            Config.shipment_inc_vat = false
            Config.shipping_tax_rate = 0
            order.create_shipment!

            adjustment.included_tax.should == 0
          end

          it "records 0% tax on shipments when a rate is set but shipment_inc_vat is false" do
            Config.shipment_inc_vat = false
            Config.shipping_tax_rate = 0.25
            order.create_shipment!

            adjustment.included_tax.should == 0
          end
        end

        describe "when tax on shipping is enabled" do
          before do
            Config.shipment_inc_vat = true
            Config.shipping_tax_rate = 0.25
            order.create_shipment!
          end

          it "takes the shipment adjustment tax included from the system setting" do
            # Finding the tax included in an amount that's already inclusive of tax:
            # total - ( total / (1 + rate) )
            # 50    - ( 50    / (1 + 0.25) )
            # = 10
            adjustment.included_tax.should == 10.00
          end

          it "records 0% tax on shipments when shipping_tax_rate is not set" do
            Config.shipment_inc_vat = true
            Config.shipping_tax_rate = nil
            order.create_shipment!

            adjustment.included_tax.should == 0
          end

          it "records 0% tax on shipments when the distributor does not charge sales tax" do
            order.distributor.update_attributes! charges_sales_tax: false
            order.reload.create_shipment!

            adjustment.included_tax.should == 0
          end
        end
      end

      describe "EnterpriseFee adjustments" do
        let!(:zone)                { create(:zone_with_member) }
        let(:fee_tax_rate)             { create(:tax_rate, included_in_price: true, calculator: Calculator::DefaultTax.new, zone: zone, amount: 0.1) }
        let(:fee_tax_category)         { create(:tax_category, tax_rates: [fee_tax_rate]) }

        let(:coordinator) { create(:distributor_enterprise, charges_sales_tax: true) }
        let(:variant)     { create(:variant, product: create(:product, tax_category: nil)) }
        let(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator, coordinator_fees: [enterprise_fee], distributors: [coordinator], variants: [variant]) }
        let!(:order)      { create(:order, order_cycle: order_cycle, distributor: coordinator) }
        let!(:line_item)  { create(:line_item, order: order, variant: variant) }
        let(:adjustment)  { order.adjustments(:reload).enterprise_fee.first }

        context "when enterprise fees have a fixed tax_category" do
          before do
            order.reload.update_distribution_charge!
          end

          context "when enterprise fees are taxed per-order" do
            let(:enterprise_fee) { create(:enterprise_fee, enterprise: coordinator, tax_category: fee_tax_category, calculator: Calculator::FlatRate.new(preferred_amount: 50.0)) }

            describe "when the tax rate includes the tax in the price" do
              it "records the tax on the enterprise fee adjustments" do
                # The fee is $50, tax is 10%, and the fee is inclusive of tax
                # Therefore, the included tax should be 0.1/1.1 * 50 = $4.55

                adjustment.included_tax.should == 4.55
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                fee_tax_rate.update_attribute :included_in_price, false
                order.reload.create_tax_charge! # Updating line_item or order has the same effect
                order.update_distribution_charge!
              end

              it "records the tax on TaxRate adjustment on the order" do
                adjustment.included_tax.should == 0
                order.adjustments.tax.first.amount.should == 5.0
              end
            end

            describe "when enterprise fees have no tax" do
              before do
                enterprise_fee.tax_category = nil
                enterprise_fee.save!
                order.update_distribution_charge!
              end

              it "records no tax as charged" do
                adjustment.included_tax.should == 0
              end
            end
          end


          context "when enterprise fees are taxed per-item" do
            let(:enterprise_fee) { create(:enterprise_fee, enterprise: coordinator, tax_category: fee_tax_category, calculator: Calculator::PerItem.new(preferred_amount: 50.0)) }

            describe "when the tax rate includes the tax in the price" do
              it "records the tax on the enterprise fee adjustments" do
                adjustment.included_tax.should == 4.55
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                fee_tax_rate.update_attribute :included_in_price, false
                order.reload.create_tax_charge!  # Updating line_item or order has the same effect
                order.update_distribution_charge!
              end

              it "records the tax on TaxRate adjustment on the order" do
                adjustment.included_tax.should == 0
                order.adjustments.tax.first.amount.should == 5.0
              end
            end
          end
        end

        context "when enterprise fees inherit their tax_category product they are applied to" do
          let(:product_tax_rate)             { create(:tax_rate, included_in_price: true, calculator: Calculator::DefaultTax.new, zone: zone, amount: 0.2) }
          let(:product_tax_category)         { create(:tax_category, tax_rates: [product_tax_rate]) }

          before do
            variant.product.update_attribute(:tax_category_id, product_tax_category.id)
            order.reload.create_tax_charge! # Updating line_item or order has the same effect
            order.reload.update_distribution_charge!
          end

          context "when enterprise fees are taxed per-order" do
            let(:enterprise_fee) { create(:enterprise_fee, enterprise: coordinator, inherits_tax_category: true, calculator: Calculator::FlatRate.new(preferred_amount: 50.0)) }

            describe "when the tax rate includes the tax in the price" do
              it "records no tax on the enterprise fee adjustments" do
                # EnterpriseFee tax category is nil and inheritance only applies to per item fees
                # so tax on the enterprise_fee adjustment will be 0
                # Tax on line item is: 0.2/1.2 x $10 = $1.67
                adjustment.included_tax.should == 0.0
                line_item.adjustments.first.included_tax.should == 1.67
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
                adjustment.included_tax.should == 0
                order.adjustments.tax.first.amount.should == 2.0
              end
            end
          end


          context "when enterprise fees are taxed per-item" do
            let(:enterprise_fee) { create(:enterprise_fee, enterprise: coordinator, inherits_tax_category: true, calculator: Calculator::PerItem.new(preferred_amount: 50.0)) }

            describe "when the tax rate includes the tax in the price" do
              it "records the tax on the enterprise fee adjustments" do
                # Applying product tax rate of 0.2 to enterprise fee of $50
                # gives tax on fee of 0.2/1.2 x $50 = $8.33
                # Tax on line item is: 0.2/1.2 x $10 = $1.67
                adjustment.included_tax.should == 8.33
                line_item.adjustments.first.included_tax.should == 1.67
              end
            end

            describe "when the tax rate does not include the tax in the price" do
              before do
                product_tax_rate.update_attribute :included_in_price, false
                order.reload.create_tax_charge!  # Updating line_item or order has the same effect
                order.update_distribution_charge!
              end

              it "records the tax on TaxRate adjustment on the order" do
                # EnterpriseFee inherits tax_category from product so total tax on
                # the order is that which applies to the line item itself, plus the
                # same rate applied to the fee of $50. ie. ($10 + $50) x 0.2 = $12.0
                adjustment.included_tax.should == 0
                order.adjustments.tax.first.amount.should == 12.0
              end
            end
          end
        end
      end

      describe "setting the included tax by tax rate" do
        let(:adjustment) { Adjustment.new label: 'foo', amount: 50 }

        it "sets it, rounding to two decimal places" do
          adjustment.set_included_tax! 0.25
          adjustment.included_tax.should == 10.00
        end
      end
    end
  end
end
