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
        LineItem.supplied_by_any([s1, s2]).sort.should == [li1, li2].sort
      end
    end
  end
end
