module Spree
  describe TaxRate do
    describe "selecting tax rates to apply to an order" do
      let!(:zone) { create(:zone_with_member) }
      let!(:order) { create(:order, distributor: hub, bill_address: create(:address)) }
      let!(:tax_rate) { create(:tax_rate, included_in_price: true, calculator: Calculator::FlatRate.new(preferred_amount: 0.1), zone: zone) }

      context "when the order's hub charges sales tax" do
        let(:hub) { create(:distributor_enterprise, charges_sales_tax: true) }

        it "selects all tax rates" do
          TaxRate.match(order).should == [tax_rate]
        end
      end

      context "when the order's hub does not charge sales tax" do
        let(:hub) { create(:distributor_enterprise, charges_sales_tax: false) }

        it "selects no tax rates" do
          TaxRate.match(order).should be_empty
        end
      end
    end
  end
end
