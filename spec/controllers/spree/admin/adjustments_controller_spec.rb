require 'spec_helper'

module Spree
  describe Admin::AdjustmentsController, type: :controller do
    include AuthenticationWorkflow

    before { login_as_admin }

    describe "setting included tax" do
      let(:order) { create(:order) }
      let(:tax_rate) { create(:tax_rate, amount: 0.1, calculator: Spree::Calculator::DefaultTax.new) }

      describe "creating an adjustment" do
        it "sets included tax to zero when no tax rate is specified" do
          spree_post :create, {order_id: order.number, adjustment: {label: 'Testing included tax', amount: '110'}, tax_rate_id: ''}
          response.should redirect_to spree.admin_order_adjustments_path(order)

          a = Adjustment.last
          a.label.should == 'Testing included tax'
          a.amount.should == 110
          a.included_tax.should == 0
        end

        it "calculates included tax when a tax rate is provided" do
          spree_post :create, {order_id: order.number, adjustment: {label: 'Testing included tax', amount: '110'}, tax_rate_id: tax_rate.id.to_s}
          response.should redirect_to spree.admin_order_adjustments_path(order)

          a = Adjustment.last
          a.label.should == 'Testing included tax'
          a.amount.should == 110
          a.included_tax.should == 10
        end
      end

      describe "updating an adjustment" do
        let(:adjustment) { create(:adjustment, adjustable: order, amount: 1100, included_tax: 100) }

        it "sets included tax to zero when no tax rate is specified" do
          spree_put :update, {order_id: order.number, id: adjustment.id, adjustment: {label: 'Testing included tax', amount: '110'}, tax_rate_id: ''}
          response.should redirect_to spree.admin_order_adjustments_path(order)

          a = Adjustment.last
          a.label.should == 'Testing included tax'
          a.amount.should == 110
          a.included_tax.should == 0
        end

        it "calculates included tax when a tax rate is provided" do
          spree_put :update, {order_id: order.number, id: adjustment.id, adjustment: {label: 'Testing included tax', amount: '110'}, tax_rate_id: tax_rate.id.to_s}
          response.should redirect_to spree.admin_order_adjustments_path(order)

          a = Adjustment.last
          a.label.should == 'Testing included tax'
          a.amount.should == 110
          a.included_tax.should == 10
        end
      end
    end
  end
end
