require 'spec_helper'

module Spree
  describe Admin::AdjustmentsController do
    include AuthenticationWorkflow

    before { login_as_admin }

    describe "setting included tax when creating an adjustment" do
      let(:order) { create(:order) }
      let(:tax_rate) { create(:tax_rate, amount: 0.1, calculator: Spree::Calculator::DefaultTax.new) }

      it "sets included tax to zero when no tax rate is specified" do
        spree_put :create, {order_id: order.number, adjustment: {label: 'Testing included tax', amount: '110'}, tax_rate_id: ''}
        response.should redirect_to spree.admin_order_adjustments_path(order)

        a = Adjustment.last
        a.label.should == 'Testing included tax'
        a.amount.should == 110
        a.included_tax.should == 0
      end

      it "calculates included tax when a tax rate is provided" do
        spree_put :create, {order_id: order.number, adjustment: {label: 'Testing included tax', amount: '110'}, tax_rate_id: tax_rate.id.to_s}
        response.should redirect_to spree.admin_order_adjustments_path(order)

        a = Adjustment.last
        a.label.should == 'Testing included tax'
        a.amount.should == 110
        a.included_tax.should == 10
      end
    end
  end
end
