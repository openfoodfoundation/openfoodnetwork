require 'spec_helper'

module Spree
  describe LineItem do
    describe "computing shipping cost for its product" do
      let(:shipping_method_10) do
        sm = create(:shipping_method, name: 'SM10')
        sm.calculator.set_preference :amount, 10
        sm
      end
      let(:shipping_method_20) do
        sm = create(:shipping_method, name: 'SM20')
        sm.calculator.set_preference :amount, 20
        sm
      end
      let(:distributor1) { create(:distributor_enterprise) }
      let(:distributor2) { create(:distributor_enterprise) }
      let!(:product) do
        p = create(:product)
        create(:product_distribution, product: p, distributor: distributor1, shipping_method: shipping_method_10)
        create(:product_distribution, product: p, distributor: distributor2, shipping_method: shipping_method_20)
        p
      end
      let(:order_d1) { create(:order, distributor: distributor1, state: 'complete') }

      it "sets distribution fee and shipping method name on creation" do
        li = create(:line_item, order: order_d1, product: product)
        li.distribution_fee.should == 10
        li.shipping_method_name.should == 'SM10'
      end

      it "updates its distribution fee & shipping method name" do
        li = create(:line_item, order: order_d1, product: product)

        li.update_distribution_fee_without_callbacks! distributor2

        li.distribution_fee.should == 20
        li.shipping_method_name.should == 'SM20'
      end

      describe "fetching its shipping method" do
        it "fetches the shipping method for its product when distributor is supplied" do
          li = create(:line_item, order: order_d1, product: product)
          li.send(:shipping_method, distributor2).should == shipping_method_20
        end

        it "uses the order's distributor when no other distributor is provided" do
          li = create(:line_item, order: order_d1, product: product)
          li.send(:shipping_method).should == shipping_method_10
        end
      end
    end
  end
end
