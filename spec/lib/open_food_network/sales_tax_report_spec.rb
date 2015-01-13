require 'open_food_network/sales_tax_report'

module OpenFoodNetwork
  describe SalesTaxReport do
    let(:report) { SalesTaxReport.new(nil) }

    describe "calculating totals for line items" do
      let(:li1) { double(:line_item, quantity: 1, amount: 12) }
      let(:li2) { double(:line_item, quantity: 2, amount: 24) }
      let(:totals) { report.send(:totals_of, [li1, li2]) }

      before do
        report.stub(:tax_included_in).and_return(2, 4)
      end

      it "calculates total quantity" do
        totals[:items].should == 3
      end

      it "calculates total price" do
        totals[:items_total].should == 36
      end

      it "calculates the taxable total price" do
        totals[:taxable_total].should == 36
      end

      it "calculates sales tax" do
        totals[:sales_tax].should == 6
      end

      context "when there is no tax on a line item" do
        before do
          report.stub(:tax_included_in) { 0 }
        end

        it "does not appear in taxable total" do
          totals[:taxable_total].should == 0
        end

        it "still appears on items total" do
          totals[:items_total].should == 36
        end

        it "does not register sales tax" do
          totals[:sales_tax].should == 0
        end
      end
    end

    describe "calculating the shipping tax on a shipping cost" do
      it "returns zero when shipping does not include VAT" do
        report.stub(:shipment_inc_vat) { false }
        report.send(:shipping_tax_on, 12).should == 0
      end

      it "returns zero when no shipping cost is passed" do
        report.stub(:shipment_inc_vat) { true }
        report.send(:shipping_tax_on, nil).should == 0
      end


      it "returns the tax included in the price otherwise" do
        report.stub(:shipment_inc_vat) { true }
        report.stub(:shipping_tax_rate) { 0.2 }
        report.send(:shipping_tax_on, 12).should == 2
      end
    end
  end
end
