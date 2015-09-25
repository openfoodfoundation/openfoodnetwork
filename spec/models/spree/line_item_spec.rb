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

    describe "checking if a line item has tax included" do
      let(:li_no_tax)   { create(:line_item) }
      let(:li_tax)      { create(:line_item) }
      let(:tax_rate)    { create(:tax_rate, calculator: Spree::Calculator::DefaultTax.new) }
      let!(:adjustment) { create(:adjustment, adjustable: li_tax, originator: tax_rate, label: "TR", amount: 123, included_tax: 10.00) }

      it "returns true when it does" do
        li_tax.should have_tax
      end

      it "returns false otherwise" do
        li_no_tax.should_not have_tax
      end
    end

    describe "unit value/description" do
      describe "generating the full name" do
        let(:li) { LineItem.new }

        before do
          li.stub(:unit_to_display) { 'unit_to_display' }
        end

        it "returns unit_to_display" do
          li.full_name.should == 'unit_to_display'
        end
      end

      describe "getting name for display" do
        it "returns product name" do
          li = create(:variant, product: create(:product))
          li.name_to_display.should == li.product.name
        end
      end

      describe "getting unit for display" do
        it "returns options_text" do
          li = create(:line_item)
          li.stub(:options_text).and_return "ponies"
          li.unit_to_display.should == "ponies"
        end
      end

      context "when the line_item already has a final_weight_volume set (and all required option values do not exist)" do
        let!(:p0) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p0, unit_value: 10, unit_description: 'bar') }

        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:li) { create(:line_item, product: p, final_weight_volume: 5) }

        it "removes the old option value and assigns the new one" do
          ov_orig = li.option_values.last
          ov_var  = v.option_values.last
          allow(li).to receive(:unit_description) { 'foo' }

          expect {
            li.update_attributes!(final_weight_volume: 10)
          }.to change(Spree::OptionValue, :count).by(1)

          li.option_values.should_not include ov_orig
          li.option_values.should_not include ov_var
          ov = li.option_values.last
          ov.name.should == "10g foo"
        end
      end

      context "when the variant already has a value set (and all required option values exist)" do
        let!(:p0) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p0, unit_value: 10, unit_description: 'bar') }

        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:li) { create(:line_item, product: p, final_weight_volume: 5) }

        it "removes the old option value and assigns the new one" do
          ov_orig = li.option_values.last
          ov_new  = v.option_values.last
          allow(li).to receive(:unit_description) { 'bar' }

          expect {
            li.update_attributes!(final_weight_volume: 10)
          }.to change(Spree::OptionValue, :count).by(0)

          li.option_values.should_not include ov_orig
          li.option_values.should     include ov_new
        end
      end
    end

    describe "deleting unit option values" do
      let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
      let!(:ot) { Spree::OptionType.find_by_name 'unit_weight' }
      let!(:li) { create(:line_item, product: p) }

      it "removes option value associations for unit option types" do
        expect {
          li.delete_unit_option_values
        }.to change(li.option_values, :count).by(-1)
      end

      it "does not delete option values" do
        expect {
          li.delete_unit_option_values
        }.to change(Spree::OptionValue, :count).by(0)
      end
    end
  end
end
