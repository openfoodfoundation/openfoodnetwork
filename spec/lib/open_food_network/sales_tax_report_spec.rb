require 'open_food_network/sales_tax_report'

module OpenFoodNetwork
  describe SalesTaxReport do
    let(:user) { create(:user) }
    let(:report) { SalesTaxReport.new(user, {}) }

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

      context "when floating point math would result in fractional cents" do
        let(:li1) { double(:line_item, quantity: 1, amount: 0.11) }
        let(:li2) { double(:line_item, quantity: 2, amount: 0.12) }

        it "rounds to the nearest cent" do
          totals[:items_total].should == 0.23
        end
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
  end
end
