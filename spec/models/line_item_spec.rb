require 'spec_helper'

module Spree
  describe LineItem do
    describe "scopes" do
      it "finds line items for products supplied by a particular enterprise" do
        o = create(:order)

        s1 = create(:supplier_enterprise)
        s2 = create(:supplier_enterprise)

        p1 = create(:simple_product, supplier: s1)
        p2 = create(:simple_product, supplier: s2)

        li1 = create(:line_item, order: o, product: p1)
        li2 = create(:line_item, order: o, product: p2)

        LineItem.supplied_by(s1).should == [li1]
        LineItem.supplied_by(s2).should == [li2]
      end
    end
  end
end
