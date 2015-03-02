module Spree
  describe Adjustment do
    it "has metadata" do
      adjustment = create(:adjustment, metadata: create(:adjustment_metadata))
      adjustment.metadata.should be
    end

    describe "recording included tax" do
      describe "TaxRate adjustments" do
        let!(:zone)        { create(:zone, default_tax: true) }
        let!(:zone_member) { ZoneMember.create!(zone: zone, zoneable: Country.find_by_name('Australia')) }
        let!(:order)       { create(:order) }
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
      end

      describe "Shipment adjustments" do
        let!(:order)          { create(:order, shipping_method: shipping_method) }
        let!(:line_item)      { create(:line_item, order: order) }
        let(:shipping_method) { create(:shipping_method, calculator: Calculator::FlatRate.new(preferred_amount: 50.0)) }
        let(:adjustment)      { order.adjustments(:reload).shipping.first }

        it "has a shipping charge of $50" do
          order.create_shipment!
          adjustment.amount.should == 50
        end

        context "when tax on shipping is disabled" do
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

        context "when tax on shipping is enabled" do
          before do
            Config.shipment_inc_vat = true
            Config.shipping_tax_rate = 0.25
            order.create_shipment!
          end

          it "takes the shipment adjustment tax included from the system setting" do
            adjustment.included_tax.should == 12.50
          end

          it "records 0% tax on shipments when shipping_tax_rate is not set" do
            Config.shipment_inc_vat = true
            Config.shipping_tax_rate = nil
            order.create_shipment!

            adjustment.included_tax.should == 0
          end
        end
      end

      describe "setting the included tax by fraction" do
        let(:adjustment) { Adjustment.new label: 'foo', amount: 123.45 }

        it "sets it, rounding to two decimal places" do
          adjustment.set_included_tax! 0.1
          adjustment.included_tax.should == 12.35
        end
      end
    end
  end
end
