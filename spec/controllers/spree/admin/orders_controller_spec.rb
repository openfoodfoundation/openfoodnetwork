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
          eligible: false,
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
        expect_any_instance_of(Spree::Order).to receive(:recreate_all_fees!)

        spree_put :update, params

        expect(response).to redirect_to spree.edit_admin_order_path(order)
      end

      context "recalculating enterprise fees" do
        let(:user) { create(:admin_user) }
        let(:variant1) { create(:variant) }
        let(:variant2) { create(:variant) }
        let(:distributor) { create(:distributor_enterprise, allow_order_changes: true) }
        let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
        let(:enterprise_fee) { create(:enterprise_fee, calculator: build(:calculator_per_item) ) }
        let!(:exchange) { create(:exchange, incoming: true, sender: variant1.product.supplier, receiver: order_cycle.coordinator, variants: [variant1, variant2], enterprise_fees: [enterprise_fee]) }
        let!(:order) do
          order = create(:completed_order_with_totals, line_items_count: 2, distributor: distributor, order_cycle: order_cycle)
          order.reload.line_items.first.update(variant_id: variant1.id)
          order.line_items.last.update(variant_id: variant2.id)
          while !order.completed? do break unless order.next! end
          order.recreate_all_fees!
          order
        end

        before do
          allow(controller).to receive(:spree_current_user) { user }
          allow(controller).to receive(:order_to_update) { order }
        end

        it "recalculates fees if the orders contents have changed" do
          expect(order.total).to eq order.item_total + (enterprise_fee.calculator.preferred_amount * 2)
          expect(order.adjustment_total).to eq enterprise_fee.calculator.preferred_amount * 2

          order.contents.add(order.line_items.first.variant, 1)

          spree_put :update, { id: order.number }

          expect(order.reload.total).to eq order.item_total + (enterprise_fee.calculator.preferred_amount * 3)
          expect(order.adjustment_total).to eq enterprise_fee.calculator.preferred_amount * 3
        end
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
            expect_any_instance_of(Spree::Order).to receive(:recreate_all_fees!)

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
end
