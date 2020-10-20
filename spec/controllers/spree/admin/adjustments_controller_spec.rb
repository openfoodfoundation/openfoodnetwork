require 'spec_helper'

module Spree
  describe Admin::AdjustmentsController, type: :controller do
    include AuthenticationHelper

    before { controller_login_as_admin }

    describe "setting included tax" do
      let(:order) { create(:order) }
      let(:tax_rate) { create(:tax_rate, amount: 0.1, calculator: ::Calculator::DefaultTax.new) }

      describe "creating an adjustment" do
        it "sets included tax to zero when no tax rate is specified" do
          spree_post :create, order_id: order.number, adjustment: { label: 'Testing included tax', amount: '110' }, tax_rate_id: ''
          expect(response).to redirect_to spree.admin_order_adjustments_path(order)

          a = Adjustment.last
          expect(a.label).to eq('Testing included tax')
          expect(a.amount).to eq(110)
          expect(a.included_tax).to eq(0)
        end

        it "calculates included tax when a tax rate is provided" do
          spree_post :create, order_id: order.number, adjustment: { label: 'Testing included tax', amount: '110' }, tax_rate_id: tax_rate.id.to_s
          expect(response).to redirect_to spree.admin_order_adjustments_path(order)

          a = Adjustment.last
          expect(a.label).to eq('Testing included tax')
          expect(a.amount).to eq(110)
          expect(a.included_tax).to eq(10)
        end
      end

      describe "updating an adjustment" do
        let(:adjustment) { create(:adjustment, adjustable: order, amount: 1100, included_tax: 100) }

        it "sets included tax to zero when no tax rate is specified" do
          spree_put :update, order_id: order.number, id: adjustment.id, adjustment: { label: 'Testing included tax', amount: '110' }, tax_rate_id: ''
          expect(response).to redirect_to spree.admin_order_adjustments_path(order)

          a = Adjustment.last
          expect(a.label).to eq('Testing included tax')
          expect(a.amount).to eq(110)
          expect(a.included_tax).to eq(0)
        end

        it "calculates included tax when a tax rate is provided" do
          spree_put :update, order_id: order.number, id: adjustment.id, adjustment: { label: 'Testing included tax', amount: '110' }, tax_rate_id: tax_rate.id.to_s
          expect(response).to redirect_to spree.admin_order_adjustments_path(order)

          a = Adjustment.last
          expect(a.label).to eq('Testing included tax')
          expect(a.amount).to eq(110)
          expect(a.included_tax).to eq(10)
        end
      end
    end
  end
end
