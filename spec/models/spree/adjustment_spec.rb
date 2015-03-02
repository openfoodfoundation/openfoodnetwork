module Spree
  describe Adjustment do
    it "has metadata" do
      adjustment = create(:adjustment, metadata: create(:adjustment_metadata))
      adjustment.metadata.should be
    end

    describe "recording included tax" do
      describe "TaxRate adjustments" do
        let!(:zone) { create(:zone, default_tax: true) }
        let!(:zone_member) { ZoneMember.create!(zone: zone, zoneable: Country.find_by_name('Australia')) }
        let!(:order) { create(:order) }
        let!(:line_item) { create(:line_item, order: order) }
        let(:tax_rate) { create(:tax_rate, included_in_price: true, calculator: Calculator::FlatRate.new(preferred_amount: 0.1)) }
        let(:adjustment) { line_item.adjustments(:reload).first }

        before do
          order.reload
          tax_rate.adjust(order)
        end

        it "has 100% tax included" do
          adjustment.amount.should be > 0
          adjustment.included_tax.should == adjustment.amount
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
