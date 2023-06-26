# frozen_string_literal: true

require 'spec_helper'

describe Spree::OrdersController, type: :controller do
  include CheckoutHelper
  include StripeStubs

  let(:distributor) { double(:distributor) }
  let(:order) { create(:order) }
  let(:order_cycle) { create(:simple_order_cycle) }

  describe "viewing an order" do
    let(:customer) { create(:customer) }
    let(:order) {
      create(:order_with_credit_payment, customer: customer, distributor: customer.enterprise)
    }

    before do
      allow(controller).to receive(:spree_current_user) { current_user }
    end

    context "after checking out as an anonymous guest" do
      let(:customer) { create(:customer, user: nil) }
      let(:current_user) { nil }

      it "loads page" do
        get :show, params: { id: order.number, order_token: order.token }
        expect(response.status).to eq 200
      end

      it "stores order token in session as 'access_token'" do
        get :show, params: { id: order.number, order_token: order.token }
        expect(session[:access_token]).to eq(order.token)
      end
    end

    context "when returning to order page after checking out as an anonymous guest" do
      let(:customer) { create(:customer, user: nil) }
      let(:current_user) { nil }

      before do
        session[:access_token] = order.token
      end

      it "loads page" do
        get :show, params: { id: order.number }
        expect(response.status).to eq 200
      end
    end

    context "when logged in as the customer" do
      let(:current_user) { order.user }

      it "loads page" do
        get :show, params: { id: order.number }
        expect(response.status).to eq 200
      end
    end

    context "when logged in as another customer" do
      let(:current_user) { create(:user) }

      it "redirects to unauthorized" do
        get :show, params: { id: order.number }
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "when neither checked out as an anonymous guest nor logged in" do
      let(:current_user) { nil }

      before do
        request.env["PATH_INFO"] = order_path(order)
      end

      it "redirects to unauthorized" do
        get :show, params: { id: order.number }
        expect(response).to redirect_to(root_path(anchor: "/login", after_login: order_path(order)))
        expect(flash[:error]).to eq("Please log in to view your order.")
      end
    end
  end

  describe "viewing cart" do
    it "redirects home when no distributor is selected" do
      get :edit
      expect(response).to redirect_to root_path
    end

    it "redirects to shop when order is empty" do
      allow(controller).to receive(:current_distributor).and_return(distributor)
      allow(controller).to receive(:current_order_cycle).and_return(order_cycle)
      allow(controller).to receive(:current_order).and_return order
      allow(order).to receive_message_chain(:line_items, :empty?).and_return true
      allow(order).to receive(:insufficient_stock_lines).and_return []
      allow(order).to receive(:line_item_variants).and_return []
      allow(order).to receive(:distributor).and_return distributor
      allow(distributor).to receive(:hide_ofn_navigation).and_return false
      allow(order_cycle).to receive(:variants_distributed_by).and_return []

      session[:access_token] = order.token
      get :edit
      expect(response).to redirect_to shop_path
    end

    it "redirects to the shop when no order cycle is selected" do
      allow(controller).to receive(:current_distributor).and_return(distributor)
      get :edit
      expect(response).to redirect_to shop_path
    end

    it "redirects home with message if hub is not ready for checkout" do
      allow(VariantOverride).to receive(:indexed).and_return({})

      order = subject.current_order(true)
      allow(distributor).to receive(:ready_for_checkout?) { false }
      allow(order).to receive_messages(distributor: distributor, order_cycle: order_cycle)

      expect(order).to receive(:empty!)
      expect(order).to receive(:set_distribution!).with(nil, nil)

      get :edit

      expect(response).to redirect_to root_url
      expect(flash[:info]).to eq('The hub you have selected is temporarily closed for orders. ' \
                                 'Please try again later.')
    end

    describe "when an item is in the cart" do
      let(:order) { subject.current_order(true) }
      let(:oc) { create(:simple_order_cycle, distributors: [d], variants: [variant]) }
      let(:d) {
        create(:distributor_enterprise, shipping_methods: [create(:shipping_method)],
                                        payment_methods: [create(:payment_method)])
      }
      let(:variant) { create(:variant, on_demand: false, on_hand: 5) }
      let(:line_item) { order.line_items.last }

      before do
        order.set_distribution! d, oc
        order.contents.add(variant, 5)
      end

      describe "the page" do
        render_views

        it "shows the right registration link" do
          # We fixed our view by hardcoding the link.
          spree_registration_path = '/signup'
          ofn_registration_path = '/register'
          get :edit
          expect(response.body).to_not match spree_registration_path
          expect(response.body).to match ofn_registration_path
        end
      end

      describe "when an item has insufficient stock" do
        before do
          variant.update! on_hand: 3
        end

        it "displays a flash message when we view the cart" do
          get :edit
          expect(response.status).to eq 200
          expect(flash[:error]).to eq 'An item in your cart has become unavailable. ' \
                                      'Please update the selected quantities.'
        end
      end

      describe "when an item is unavailable" do
        before do
          order.order_cycle = create(:simple_order_cycle, distributors: [d], variants: [])
        end

        it "displays a flash message when we view the cart" do
          get :edit
          expect(response.status).to eq 200
          expect(flash[:error]).to eq 'An item in your cart has become unavailable. ' \
                                      'Please update the selected quantities.'
        end
      end
    end
  end

  describe "removing line items from cart" do
    describe "when I pass params that includes a line item no longer in our cart" do
      it "should silently ignore the missing line item" do
        order = subject.current_order(true)
        li = order.contents.add(create(:simple_product, on_hand: 110).variants.first)
        get :update, params: { order: { line_items_attributes: {
          "0" => { quantity: "0", id: "9999" },
          "1" => { quantity: "99", id: li.id }
        } } }
        expect(response.status).to eq(302)
        expect(li.reload.quantity).to eq(99)
      end
    end

    it "filters line items that are missing from params" do
      order = subject.current_order(true)
      li = order.contents.add(create(:simple_product).variants.first)

      attrs = {
        "0" => { quantity: "0", id: "9999" },
        "1" => { quantity: "99", id: li.id }
      }

      expect(controller.__send__(:remove_missing_line_items, attrs)).to eq(
        "1" => { quantity: "99", id: li.id }
      )
    end

    it "keeps the adjustments' previous state" do
      order = subject.current_order(true)
      line_item = order.contents.add(create(:simple_product, on_hand: 110).variants.first)
      adjustment = create(:adjustment, adjustable: order)

      get :update, params: { order: { line_items_attributes: {
        "1" => { quantity: "99", id: line_item.id }
      } } }

      expect(adjustment.state).to eq('open')
    end
  end

  describe "removing items from a completed order" do
    context "with shipping and transaction fees" do
      let(:distributor) {
        create(:distributor_enterprise, charges_sales_tax: true, allow_order_changes: true)
      }
      let(:shipping_tax_rate) {
        create(:tax_rate, amount: 0.25, included_in_price: true, zone: create(:zone_with_member))
      }
      let(:shipping_tax_category) { create(:tax_category, tax_rates: [shipping_tax_rate]) }
      let(:order) {
        create(:completed_order_with_fees, distributor: distributor, shipping_fee: shipping_fee,
                                           payment_fee: payment_fee,
                                           shipping_tax_category: shipping_tax_category)
      }
      let(:line_item1) { order.line_items.first }
      let(:line_item2) { order.line_items.second }
      let(:shipping_fee) { 3 }
      let(:payment_fee) { 5 }
      let(:item_num) { order.line_items.length }
      let(:expected_fees) { item_num * (shipping_fee + payment_fee) }

      before do
        allow(order).to receive(:tax_zone) { shipping_tax_rate.zone }
        order.reload
        order.create_tax_charge!

        # Sanity check the fees
        expect(order.all_adjustments.length).to eq 3
        expect(item_num).to eq 2
        expect(order.adjustment_total).to eq expected_fees
        expect(order.shipment.adjustments.tax.first.amount).to eq 1.2
        expect(order.shipment.included_tax_total).to eq 1.2

        allow(subject).to receive(:spree_current_user) { order.user }
        allow(subject).to receive(:order_to_update) { order }
      end

      it "updates the shipping and payment fees" do
        spree_post :update,
                   order: { line_items_attributes: {
                     "0" => { id: line_item1.id, quantity: 1 },
                     "1" => { id: line_item2.id, quantity: 0 }
                   } }

        expect(order.reload.line_items.count).to eq 1
        expect(order.adjustment_total).to eq(1 * (shipping_fee + payment_fee))
        expect(order.shipment.adjustments.tax.first.amount).to eq 0.6
        expect(order.shipment.included_tax_total).to eq 0.6
      end
    end

    context "with enterprise fees" do
      let(:user) { create(:user) }
      let(:variant1) { create(:variant) }
      let(:variant2) { create(:variant) }
      let(:distributor) { create(:distributor_enterprise, allow_order_changes: true) }
      let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
      let(:enterprise_fee) { create(:enterprise_fee, calculator: build(:calculator_per_item) ) }
      let!(:exchange) {
        create(:exchange, incoming: true, sender: variant1.product.supplier,
                          receiver: order_cycle.coordinator, variants: [variant1, variant2],
                          enterprise_fees: [enterprise_fee])
      }
      let!(:order) do
        order = create(:completed_order_with_totals, line_items_count: 2, user: user,
                                                     distributor: distributor,
                                                     order_cycle: order_cycle)
        order.reload.line_items.first.update(variant_id: variant1.id)
        order.reload.line_items.last.update(variant_id: variant2.id)
        break unless order.next! while !order.completed?
        order.recreate_all_fees!
        order
      end
      let(:params) {
        { order: { line_items_attributes: {
          "0" => { id: order.line_items.first.id, quantity: 2 }
        } } }
      }

      before do
        allow(subject).to receive(:spree_current_user) { order.user }
        allow(subject).to receive(:order_to_update) { order }
      end

      it "updates the fees" do
        expect(order.total)
          .to eq order.item_total + (enterprise_fee.calculator.preferred_amount * 2)
        expect(order.adjustment_total).to eq enterprise_fee.calculator.preferred_amount * 2

        allow(controller).to receive_messages spree_current_user: user
        spree_post :update, params

        expect(order.total)
          .to eq order.item_total + (enterprise_fee.calculator.preferred_amount * 3)
        expect(order.adjustment_total).to eq enterprise_fee.calculator.preferred_amount * 3
      end

      context "when a line item is removed" do
        let(:params) {
          { order: { line_items_attributes: {
            "0" => { id: order.line_items.first.id, quantity: 0 },
            "1" => { id: order.line_items.last.id, quantity: 1 }
          } } }
        }

        it "updates the fees" do
          expect(order.total)
            .to eq order.item_total + (enterprise_fee.calculator.preferred_amount * 2)
          expect(order.adjustment_total).to eq enterprise_fee.calculator.preferred_amount * 2

          allow(controller).to receive_messages spree_current_user: user
          spree_post :update, params

          expect(order.total)
            .to eq order.item_total + (enterprise_fee.calculator.preferred_amount * 1)
          expect(order.adjustment_total).to eq enterprise_fee.calculator.preferred_amount * 1
        end
      end
    end
  end

  describe "request to remove items from a completed order" do
    let(:order) { create(:completed_order_with_totals, line_items_count: 2) }
    let(:params) {
      { order: { line_items_attributes: {
        "0" => { id: order.line_items.first.id, quantity: 1 },
        "1" => { id: order.line_items.second.id, quantity: 0 }
      } } }
    }

    before { allow(subject).to receive(:order_to_update) { order } }

    context "one item would remain in the order" do
      it "removes the items" do
        spree_post :update, params
        expect(flash[:error]).to be nil
        expect(response).to redirect_to order_path(order)
        expect(order.reload.line_items.count).to eq 1
      end
    end

    context "no item would remain in the order" do
      before { params[:order][:line_items_attributes]["0"][:quantity] = 0 }

      it "does not remove items, flash suggests cancellation" do
        spree_post :update, params
        expect(flash[:error])
          .to eq 'Cannot remove the final item from an order, please cancel the order instead.'
        expect(response).to redirect_to order_path(order)
        expect(order.reload.line_items.count).to eq 2
      end
    end
  end

  describe "#order_to_update" do
    let!(:current_order) { double(:current_order) }
    let(:params) { {} }

    before do
      allow(controller).to receive(:current_order) { current_order }
      allow(controller).to receive(:params) { params }
    end

    context "when no order id is given in params" do
      it "returns the current_order" do
        expect(controller.send(:order_to_update)).to eq current_order
      end
    end

    context "when an order_id is given in params" do
      before do
        params.merge!(id: order.number)
      end

      context "and the order is not complete" do
        let!(:order) { create(:order) }

        it "returns nil" do
          expect(controller.send(:order_to_update)).to eq nil
        end
      end

      context "and the order is complete" do
        let!(:order) { create(:completed_order_with_totals) }

        context "and the user doesn't have permisson to 'update' the order" do
          before { allow(controller).to receive(:can?).with(:update, order) { false } }

          it "returns nil" do
            expect(controller.send(:order_to_update)).to eq nil
          end
        end

        context "and the user has permission to 'update' the order" do
          before { allow(controller).to receive(:can?).with(:update, order) { true } }

          context "and the order is not editable" do
            it "returns nil" do
              expect(controller.send(:order_to_update)).to eq nil
            end
          end

          context "and the order is editable" do
            let(:distributor) { create(:enterprise, allow_order_changes: true) }
            let(:order_cycle) do
              create(
                :simple_order_cycle,
                distributors: [distributor],
                variants: order.line_item_variants
              )
            end

            before do
              order.update!(order_cycle_id: order_cycle.id, distributor_id: distributor.id)
            end

            it "returns the order" do
              expect(controller.send(:order_to_update)).to eq order
            end
          end
        end
      end
    end
  end

  describe "cancelling an order" do
    let(:user) { create(:user) }
    let(:order) { create(:order, user: user) }
    let(:params) { { id: order.number } }

    context "when the user does not have permission to cancel the order" do
      before { allow(controller).to receive(:spree_current_user) { create(:user) } }

      it "responds with unauthorized" do
        spree_put :cancel, params
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "when the user has permission to cancel the order" do
      before { allow(controller).to receive(:spree_current_user) { user } }

      context "when the order is not yet complete" do
        it "responds with forbidden" do
          spree_put :cancel, params

          expect(response).to have_http_status(:found)
          expect(response.body).to match(order_path(order)).and match("redirect")
          expect(flash[:error]).to eq 'Sorry, the order could not be cancelled'
        end
      end

      context "when the order is complete" do
        let(:order) {
          create(:completed_order_with_totals, user: user,
                                               distributor: create(:distributor_enterprise))
        }

        it "responds with success" do
          spree_put :cancel, params

          expect(response).to have_http_status(:found)
          expect(response.body).to match(order_path(order)).and match("redirect")
          expect(flash[:success]).to eq 'Your order has been cancelled'
        end
      end
    end
  end

  private

  def num_items_in_cart
    Spree::Order.last&.line_items&.count || 0
  end
end
