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

    describe "setting the adjustment's tax" do
      let(:order) { create(:order) }
      let(:zone) { create(:zone_with_member) }
      let(:tax_rate) { create(:tax_rate, amount: 0.1, zone: zone, included_in_price: true ) }

      describe "creating an adjustment" do
        let(:tax_category_param) { '' }
        let(:params) {
          {
            order_id: order.number,
            adjustment: {
              label: 'Testing included tax', amount: '110', tax_category_id: tax_category_param
            }
          }
        }

        context "when no tax category is specified" do
          it "doesn't apply tax" do
            spree_post :create, params
            expect(response).to redirect_to spree.admin_order_adjustments_path(order)

            new_adjustment = Adjustment.admin.last

            expect(new_adjustment.label).to eq('Testing included tax')
            expect(new_adjustment.amount).to eq(110)
            expect(new_adjustment.tax_category).to be_nil
            expect(new_adjustment.order_id).to eq(order.id)

            expect(order.reload.total).to eq 110
            expect(order.included_tax_total).to eq 0
          end
        end

        context "when a tax category is provided" do
          let(:tax_category_param) { tax_rate.tax_category.id.to_s }

          it "applies tax" do
            spree_post :create, params
            expect(response).to redirect_to spree.admin_order_adjustments_path(order)

            new_adjustment = Adjustment.admin.last

            expect(new_adjustment.label).to eq('Testing included tax')
            expect(new_adjustment.amount).to eq(110)
            expect(new_adjustment.tax_category).to eq tax_rate.tax_category
            expect(new_adjustment.order_id).to eq(order.id)

            expect(order.reload.total).to eq 110
            expect(order.included_tax_total).to eq 10
          end
        end

        context "when the tax category has multiple rates for the same tax zone" do
          let(:tax_category) { create(:tax_category) }
          let!(:tax_rate1) {
            create(:tax_rate, amount: 0.1, zone: zone, included_in_price: false,
                              tax_category: tax_category )
          }
          let!(:tax_rate2) {
            create(:tax_rate, amount: 0.2, zone: zone, included_in_price: false,
                              tax_category: tax_category )
          }
          let(:tax_category_param) { tax_category.id.to_s }
          let(:params) {
            {
              order_id: order.number,
              adjustment: {
                label: 'Testing multiple rates', amount: '100', tax_category_id: tax_category_param
              }
            }
          }

          it "applies both rates" do
            spree_post :create, params
            expect(response).to redirect_to spree.admin_order_adjustments_path(order)

            new_adjustment = Adjustment.admin.last

            expect(new_adjustment.amount).to eq(100)
            expect(new_adjustment.tax_category).to eq tax_category
            expect(new_adjustment.order_id).to eq(order.id)
            expect(new_adjustment.adjustments.tax.count).to eq 2

            expect(order.reload.total).to eq 130
            expect(order.additional_tax_total).to eq 30
          end
        end
      end

      describe "updating an adjustment" do
        let(:old_tax_category) { create(:tax_category) }
        let(:tax_category_param) { '' }
        let(:params) {
          {
            id: adjustment.id,
            order_id: order.number,
            adjustment: {
              label: 'Testing included tax', amount: '110', tax_category_id: tax_category_param
            }
          }
        }
        let(:adjustment) {
          create(:adjustment, adjustable: order, order: order,
                              amount: 1100, tax_category: old_tax_category)
        }

        context "when no tax category is specified" do
          it "doesn't apply tax" do
            spree_put :update, params
            expect(response).to redirect_to spree.admin_order_adjustments_path(order)

            adjustment = Adjustment.admin.last

            expect(adjustment.label).to eq('Testing included tax')
            expect(adjustment.amount).to eq(110)
            expect(adjustment.tax_category).to be_nil
            expect(adjustment.order_id).to eq(order.id)

            expect(order.reload.total).to eq 110
            expect(order.included_tax_total).to eq 0
          end
        end

        context "when a tax category is provided" do
          let(:tax_category_param) { tax_rate.tax_category.id.to_s }

          it "applies tax" do
            spree_put :update, params
            expect(response).to redirect_to spree.admin_order_adjustments_path(order)

            adjustment = Adjustment.admin.last

            expect(adjustment.label).to eq('Testing included tax')
            expect(adjustment.amount).to eq(110)
            expect(adjustment.tax_category).to eq tax_rate.tax_category
            expect(adjustment.order_id).to eq(order.id)

            expect(order.reload.total).to eq 110
            expect(order.included_tax_total).to eq 10
          end
        end
      end
    end

    describe "#delete" do
      let!(:order) { create(:completed_order_with_totals) }
      let(:payment_fee) {
        create(:adjustment, amount: 0.50, order: order, adjustable: order.payments.first)
      }

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
        create(:adjustment, adjustable: order, order: order, amount: 1100)
      }

      before do
        expect(order.cancel).to eq true
      end

      it "doesn't create adjustments" do
        expect {
          spree_post :create, order_id: order.number,
                              adjustment: { label: "Testing", amount: "110" }
        }.to_not change { [Adjustment.count, order.reload.total] }

        expect(response).to redirect_to spree.admin_order_adjustments_path(order)
      end

      it "doesn't change adjustments" do
        expect {
          spree_put :update, order_id: order.number, id: adjustment.id,
                             adjustment: { label: "Testing", amount: "110" }
        }.to_not change { [adjustment.reload.amount, order.reload.total] }

        expect(response).to redirect_to spree.admin_order_adjustments_path(order)
      end
    end
  end
end
