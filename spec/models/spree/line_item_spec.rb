require 'spec_helper'

module Spree
  describe LineItem do
    describe "scopes" do
      let(:o) { create(:order) }

      let(:s1) { create(:supplier_enterprise) }
      let(:s2) { create(:supplier_enterprise) }

      let(:p1) { create(:simple_product, supplier: s1) }
      let(:p2) { create(:simple_product, supplier: s2) }

      let(:li1) { create(:line_item, order: o, product: p1) }
      let(:li2) { create(:line_item, order: o, product: p2) }

      it "finds line items for products supplied by a particular enterprise" do
        LineItem.supplied_by(s1).should == [li1]
        LineItem.supplied_by(s2).should == [li2]
      end

      it "finds line items for products supplied by one of a number of enterprises" do
        LineItem.supplied_by_any([s1]).should == [li1]
        LineItem.supplied_by_any([s2]).should == [li2]
        LineItem.supplied_by_any([s1, s2]).should match_array [li1, li2]
      end

      describe "finding line items with and without tax" do
        let(:tax_rate) { create(:tax_rate, calculator: Spree::Calculator::DefaultTax.new) }
        let!(:adjustment1) { create(:adjustment, adjustable: li1, originator: tax_rate, label: "TR", amount: 123, included_tax: 10.00) }
        let!(:adjustment2) { create(:adjustment, adjustable: li1, originator: tax_rate, label: "TR", amount: 123, included_tax: 10.00) }

        before { li1; li2 }

        it "finds line items with tax" do
          LineItem.with_tax.should == [li1]
        end

        it "finds line items without tax" do
          LineItem.without_tax.should == [li2]
        end
      end
    end

    describe "calculating price with adjustments" do
      it "does not return fractional cents" do
        li = LineItem.new

        li.stub(:price) { 55.55 }
        li.stub_chain(:order, :adjustments, :where, :sum) { 11.11 }
        li.stub(:quantity) { 2 }
        li.price_with_adjustments.should == 61.11
      end
    end

    describe "calculating amount with adjustments" do
      it "returns a value consistent with price_with_adjustments" do
        li = LineItem.new

        li.stub(:price) { 55.55 }
        li.stub_chain(:order, :adjustments, :where, :sum) { 11.11 }
        li.stub(:quantity) { 2 }
        li.amount_with_adjustments.should == 122.22
      end
    end

    describe "tax" do
      let(:li_no_tax)   { create(:line_item) }
      let(:li_tax)      { create(:line_item) }
      let(:tax_rate)    { create(:tax_rate, calculator: Spree::Calculator::DefaultTax.new) }
      let!(:adjustment) { create(:adjustment, adjustable: li_tax, originator: tax_rate, label: "TR", amount: 123, included_tax: 10.00) }

      context "checking if a line item has tax included" do
        it "returns true when it does" do
          expect(li_tax).to have_tax
        end

        it "returns false otherwise" do
          expect(li_no_tax).to_not have_tax
        end
      end

      context "calculating the amount of included tax" do
        it "returns the included tax when present" do
          expect(li_tax.included_tax).to eq 10.00
        end

        it "returns 0.00 otherwise" do
          expect(li_no_tax.included_tax).to eq 0.00
        end
      end
    end
  end
end
