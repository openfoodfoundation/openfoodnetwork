# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::OrdersController, type: :controller do
  include OpenFoodNetwork::EmailHelper

  describe "#edit" do
    let!(:order) { create(:order_with_totals_and_distribution, ship_address: create(:address)) }

    before { controller_login_as_admin }

    it "advances the order state" do
      expect {
        spree_get :edit, id: order
      }.to change { order.reload.state }.from("cart").to("payment")
    end

    describe "view" do
      render_views

      it "shows only eligible adjustments" do
        adjustment = create(
          :adjustment,
          adjustable: order,
          label: "invalid adjustment",
          amount: 0
        )

        spree_get :edit, id: order

        expect(response.body).to_not match adjustment.label
      end
    end
  end

  context "#update" do
    let(:params) do
      { id: order,
        order: { number: order.number,
                 distributor_id: order.distributor_id,
                 order_cycle_id: order.order_cycle_id } }
    end

    before { controller_login_as_admin }

    context "complete order" do
      let(:order) { create :completed_order_with_totals }

      it "does not throw an error if no order object is given in params" do
        params = { id: order }

        spree_put :update, params

        expect(response.status).to eq 302
      end

      it "updates distribution charges and redirects to order details page" do
        expect_any_instance_of(Spree::Order).to receive(:update_distribution_charge!)

        spree_put :update, params

        expect(response).to redirect_to spree.edit_admin_order_path(order)
      end
    end

    context "incomplete order" do
      let(:order) { create(:order) }
      let(:line_item) { create(:line_item) }

      context "without line items" do
        it "redirects to order details page with flash error" do
          spree_put :update, params

          expect(flash[:error]).to eq "Line items can't be blank"
          expect(response).to redirect_to spree.edit_admin_order_path(order)
        end
      end

      context "with line items" do
        before do
          order.line_items << line_item
          order.save
          params[:order][:line_items_attributes] = [{ id: line_item.id, quantity: line_item.quantity }]
        end

        context "and no errors" do
          it "updates distribution charges and redirects to customer details page" do
            expect_any_instance_of(Spree::Order).to receive(:update_distribution_charge!)

            spree_put :update, params

            expect(response).to redirect_to spree.admin_order_customer_path(order)
          end
        end

        context "with invalid distributor" do
          it "redirects to order details page with flash error" do
            params[:order][:distributor_id] = create(:distributor_enterprise).id

            spree_put :update, params

            expect(flash[:error]).to eq "Distributor or order cycle cannot supply the products in your cart"
            expect(response).to redirect_to spree.edit_admin_order_path(order)
          end
        end
      end
    end
  end

  describe "#index" do
    context "as a regular user" do
      before { allow(controller).to receive(:spree_current_user) { create(:user) } }

      it "should deny me access to the index action" do
        spree_get :index
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "as an enterprise user" do
      let!(:order) { create(:order_with_distributor) }

      before { allow(controller).to receive(:spree_current_user) { order.distributor.owner } }

      it "should allow access" do
        expect(response.status).to eq 200
      end
    end
  end

  describe "#invoice" do
    let!(:user) { create(:user) }
    let!(:enterprise_user) { create(:user) }
    let!(:order) { create(:order_with_distributor, bill_address: create(:address), ship_address: create(:address)) }
    let!(:distributor) { order.distributor }
    let(:params) { { id: order.number } }

    context "as a normal user" do
      before { allow(controller).to receive(:spree_current_user) { user } }

      it "should prevent me from sending order invoices" do
        spree_get :invoice, params
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "as an enterprise user" do
      context "which is not a manager of the distributor for an order" do
        before { allow(controller).to receive(:spree_current_user) { user } }

        it "should prevent me from sending order invoices" do
          spree_get :invoice, params
          expect(response).to redirect_to unauthorized_path
        end
      end

      context "which is a manager of the distributor for an order" do
        before { allow(controller).to receive(:spree_current_user) { distributor.owner } }

        context "when the distributor's ABN has not been set" do
          before { distributor.update_attribute(:abn, "") }
          it "should allow me to send order invoices" do
            expect do
              spree_get :invoice, params
            end.to_not change{ Spree::OrderMailer.deliveries.count }
            expect(response).to redirect_to spree.edit_admin_order_path(order)
            expect(flash[:error]).to eq "#{distributor.name} must have a valid ABN before invoices can be sent."
          end
        end

        context "when the distributor's ABN has been set" do
          before { distributor.update_attribute(:abn, "123") }
          before do
            ActionMailer::Base.perform_deliveries = true
            setup_email
          end

          it "should allow me to send order invoices" do
            expect do
              spree_get :invoice, params
            end.to change{ Spree::OrderMailer.deliveries.count }.by(1)
            expect(response).to redirect_to spree.edit_admin_order_path(order)
          end
        end
      end
    end
  end

  describe "#print" do
    let!(:user) { create(:user) }
    let!(:enterprise_user) { create(:user) }
    let!(:order) { create(:order_with_distributor, bill_address: create(:address), ship_address: create(:address)) }
    let!(:distributor) { order.distributor }
    let(:params) { { id: order.number } }

    context "as a normal user" do
      before { allow(controller).to receive(:spree_current_user) { user } }

      it "should prevent me from sending order invoices" do
        spree_get :print, params
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "as an enterprise user" do
      context "which is not a manager of the distributor for an order" do
        before { allow(controller).to receive(:spree_current_user) { user } }
        it "should prevent me from sending order invoices" do
          spree_get :print, params
          expect(response).to redirect_to unauthorized_path
        end
      end

      context "which is a manager of the distributor for an order" do
        before { allow(controller).to receive(:spree_current_user) { distributor.owner } }
        it "should allow me to send order invoices" do
          spree_get :print, params
          expect(response).to render_template :invoice
        end
      end
    end
  end
end
