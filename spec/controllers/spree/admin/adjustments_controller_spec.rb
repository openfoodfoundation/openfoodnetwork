# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe Admin::AdjustmentsController, type: :controller do
    include AuthenticationHelper

    before { controller_login_as_admin }

    describe "index" do
      let!(:order) { create(:completed_order_with_totals) }
      let!(:adjustment1) {
        create(:adjustment, originator_type: "Spree::ShippingMethod", order: order,
                            adjustable: order.shipment)
      }
      let!(:adjustment2) {
        create(:adjustment, originator_type: "Spree::PaymentMethod", eligible: true, order: order)
      }
      let!(:adjustment3) {
        create(:adjustment, originator_type: "Spree::PaymentMethod", eligible: false, order: order)
      }
      let!(:adjustment4) { create(:adjustment, originator_type: "EnterpriseFee", order: order) }
      let!(:adjustment5) { create(:adjustment, originator: nil, adjustable: order, order: order) }

      it "displays eligible adjustments" do
        spree_get :index, order_id: order.number

        expect(assigns(:collection)).to include adjustment1, adjustment2
        expect(assigns(:collection)).to_not include adjustment3
      end

      it "displays admin adjustments" do
        spree_get :index, order_id: order.number

        expect(assigns(:collection)).to include adjustment5
      end

      it "does not display enterprise fee adjustments" do
        spree_get :index, order_id: order.number

        expect(assigns(:collection)).to_not include adjustment4
      end
    end

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
          expect(a.order_id).to eq(order.id)

          expect(order.reload.total).to eq 110
        end

        it "calculates included tax when a tax rate is provided" do
          spree_post :create, order_id: order.number, adjustment: { label: 'Testing included tax', amount: '110' }, tax_rate_id: tax_rate.id.to_s
          expect(response).to redirect_to spree.admin_order_adjustments_path(order)

          a = Adjustment.last
          expect(a.label).to eq('Testing included tax')
          expect(a.amount).to eq(110)
          expect(a.included_tax).to eq(10)
          expect(a.order_id).to eq(order.id)

          expect(order.reload.total).to eq 110
        end
      end

      describe "updating an adjustment" do
        let(:adjustment) {
          create(:adjustment, adjustable: order, order: order, amount: 1100, included_tax: 100)
        }

        it "sets included tax to zero when no tax rate is specified" do
          spree_put :update, order_id: order.number, id: adjustment.id, adjustment: { label: 'Testing included tax', amount: '110' }, tax_rate_id: ''
          expect(response).to redirect_to spree.admin_order_adjustments_path(order)

          a = Adjustment.last
          expect(a.label).to eq('Testing included tax')
          expect(a.amount).to eq(110)
          expect(a.included_tax).to eq(0)
          expect(a.order_id).to eq(order.id)

          expect(order.reload.total).to eq 110
        end

        it "calculates included tax when a tax rate is provided" do
          spree_put :update, order_id: order.number, id: adjustment.id, adjustment: { label: 'Testing included tax', amount: '110' }, tax_rate_id: tax_rate.id.to_s
          expect(response).to redirect_to spree.admin_order_adjustments_path(order)

          a = Adjustment.last
          expect(a.label).to eq('Testing included tax')
          expect(a.amount).to eq(110)
          expect(a.included_tax).to eq(10)
          expect(a.order_id).to eq(order.id)

          expect(order.reload.total).to eq 110
        end
      end
    end

    describe "#delete" do
      let!(:order) { create(:completed_order_with_totals) }
      let(:payment_fee) { create(:adjustment, amount: 0.50, order: order, adjustable: order.payments.first) }

      context "as an enterprise user with edit permissions on the order" do
        before do
          order.adjustments << payment_fee
          controller_login_as_enterprise_user([order.distributor])
        end

        it "deletes the adjustment" do
          spree_delete :destroy, order_id: order.number, id: payment_fee.id

          expect(response).to redirect_to spree.admin_order_adjustments_path(order)
          expect(order.reload.all_adjustments.count).to be_zero
        end
      end

      context "as an enterprise user with no permissions on the order" do
        before do
          order.adjustments << payment_fee
          controller_login_as_enterprise_user([create(:enterprise)])
        end

        it "is unauthorized, does not delete the adjustment" do
          spree_delete :destroy, order_id: order.number, id: payment_fee.id

          expect(response).to redirect_to unauthorized_path
          expect(order.reload.all_adjustments.count).to eq 1
        end
      end
    end

    describe "with a cancelled order" do
      let(:order) { create(:completed_order_with_totals) }
      let(:tax_rate) { create(:tax_rate, amount: 0.1, calculator: ::Calculator::DefaultTax.new) }
      let(:adjustment) {
        create(:adjustment, adjustable: order, order: order, amount: 1100, included_tax: 100)
      }

      before do
        expect(order.cancel).to eq true
      end

      it "doesn't create adjustments" do
        expect {
          spree_post :create, order_id: order.number, adjustment: { label: "Testing", amount: "110" }, tax_rate_id: ""
        }.to_not change { [Adjustment.count, order.reload.total] }

        expect(response).to redirect_to spree.admin_order_adjustments_path(order)
      end

      it "doesn't change adjustments" do
        expect {
          spree_put :update, order_id: order.number, id: adjustment.id, adjustment: { label: "Testing", amount: "110" }, tax_rate_id: ""
        }.to_not change { [adjustment.reload.amount, order.reload.total] }

        expect(response).to redirect_to spree.admin_order_adjustments_path(order)
      end
    end
  end
end
