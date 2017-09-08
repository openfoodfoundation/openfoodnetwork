module Spree
  describe TaxRate do
    describe "selecting tax rates to apply to an order" do
      let!(:zone) { create(:zone_with_member) }
      let!(:order) { create(:order, distributor: hub, bill_address: create(:address)) }
      let!(:tax_rate) { create(:tax_rate, included_in_price: true, calculator: Calculator::FlatRate.new(preferred_amount: 0.1), zone: zone) }

      describe "when the order's hub charges sales tax" do
        let(:hub) { create(:distributor_enterprise, charges_sales_tax: true) }

        it "selects all tax rates" do
          TaxRate.match(order).should == [tax_rate]
        end
      end

      describe "when the order's hub does not charge sales tax" do
        let(:hub) { create(:distributor_enterprise, charges_sales_tax: false) }

        it "selects no tax rates" do
          TaxRate.match(order).should be_empty
        end
      end

      describe "when the order does not have a hub" do
        let!(:order) { create(:order, distributor: nil, bill_address: create(:address)) }

        it "selects all tax rates" do
          TaxRate.match(order).should == [tax_rate]
        end
      end
    end

    describe "ensuring that tax rate is marked as tax included_in_price" do
      let(:tax_rate) { create(:tax_rate, included_in_price: false, calculator: Spree::Calculator::DefaultTax.new) }

      it "sets included_in_price to true" do
        tax_rate.send(:with_tax_included_in_price) do
          tax_rate.included_in_price.should be true
        end
      end

      it "sets the included_in_price value accessible to the calculator to true" do
        tax_rate.send(:with_tax_included_in_price) do
          tax_rate.calculator.calculable.included_in_price.should be true
        end
      end

      it "passes through the return value of the block" do
        tax_rate.send(:with_tax_included_in_price) do
          'asdf'
        end.should == 'asdf'
      end

      it "restores both values to their original afterwards" do
        tax_rate.send(:with_tax_included_in_price) {}
        tax_rate.included_in_price.should be false
        tax_rate.calculator.calculable.included_in_price.should be false
      end

      it "restores both values when an exception is raised" do
        expect do
          tax_rate.send(:with_tax_included_in_price) { raise Exception.new 'oops' }
        end.to raise_error 'oops'

        tax_rate.included_in_price.should be false
        tax_rate.calculator.calculable.included_in_price.should be false
      end
    end
  end
end
