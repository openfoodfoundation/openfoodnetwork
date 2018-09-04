require 'spec_helper'

describe Spree::OrdersController, type: :controller do
  let(:distributor) { double(:distributor) }
  let(:order) { create(:order) }
  let(:order_cycle) { create(:simple_order_cycle) }

  it "redirects home when no distributor is selected" do
    spree_get :edit
    expect(response).to redirect_to root_path
  end

  it "redirects to shop when order is empty" do
    allow(controller).to receive(:current_distributor).and_return(distributor)
    allow(controller).to receive(:current_order_cycle).and_return(order_cycle)
    allow(controller).to receive(:current_order).and_return order
    allow(order).to receive_message_chain(:line_items, :empty?).and_return true
    allow(order).to receive(:insufficient_stock_lines).and_return []
    session[:access_token] = order.token
    spree_get :edit
    expect(response).to redirect_to shop_path
  end

  it "redirects to the shop when no order cycle is selected" do
    allow(controller).to receive(:current_distributor).and_return(distributor)
    spree_get :edit
    expect(response).to redirect_to shop_path
  end

  it "redirects home with message if hub is not ready for checkout" do
    allow(VariantOverride).to receive(:indexed).and_return({})

    order = subject.current_order(true)
    allow(distributor).to receive(:ready_for_checkout?) { false }
    allow(order).to receive_messages(distributor: distributor, order_cycle: order_cycle)

    expect(order).to receive(:empty!)
    expect(order).to receive(:set_distribution!).with(nil, nil)

    spree_get :edit

    expect(response).to redirect_to root_url
    expect(flash[:info]).to eq("The hub you have selected is temporarily closed for orders. Please try again later.")
  end

  describe "when an item has insufficient stock" do
    let(:order) { subject.current_order(true) }
    let(:oc) { create(:simple_order_cycle, distributors: [d], variants: [variant]) }
    let(:d) { create(:distributor_enterprise, shipping_methods: [create(:shipping_method)], payment_methods: [create(:payment_method)]) }
    let(:variant) { create(:variant, on_demand: false, on_hand: 5) }
    let(:line_item) { order.line_items.last }

    before do
      order.set_distribution! d, oc
      order.add_variant variant, 5
      variant.update_attributes! on_hand: 3
    end

    it "displays a flash message when we view the cart" do
      spree_get :edit
      expect(response.status).to eq 200
      expect(flash[:error]).to eq("An item in your cart has become unavailable.")
    end
  end

  describe "removing line items from cart" do
    describe "when I pass params that includes a line item no longer in our cart" do
      it "should silently ignore the missing line item" do
        order = subject.current_order(true)
        li = order.add_variant(create(:simple_product, on_hand: 110).variants.first)
        spree_get :update, order: { line_items_attributes: {
          "0" => {quantity: "0", id: "9999"},
          "1" => {quantity: "99", id: li.id}
        }}
        expect(response.status).to eq(302)
        expect(li.reload.quantity).to eq(99)
      end
    end

    it "filters line items that are missing from params" do
      order = subject.current_order(true)
      li = order.add_variant(create(:simple_product).master)

      attrs = {
        "0" => {quantity: "0", id: "9999"},
        "1" => {quantity: "99", id: li.id}
      }

      expect(controller.remove_missing_line_items(attrs)).to eq({
        "1" => {quantity: "99", id: li.id}
      })
    end
  end

  describe "removing items from a completed order" do
    context "with shipping and transaction fees" do
      let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true, allow_order_changes: true) }
      let(:order) { create(:completed_order_with_fees, distributor: distributor, shipping_fee: shipping_fee, payment_fee: payment_fee) }
      let(:line_item1) { order.line_items.first }
      let(:line_item2) { order.line_items.second }
      let(:shipping_fee) { 3 }
      let(:payment_fee) { 5 }
      let(:item_num) { order.line_items.length }
      let(:expected_fees) { item_num * (shipping_fee + payment_fee) }
      let(:params) { { order: { line_items_attributes: {
        "0" => {id: line_item1.id, quantity: 1},
        "1" => {id: line_item2.id, quantity: 0}
      } } } }

      before do
        Spree::Config.shipment_inc_vat = true
        Spree::Config.shipping_tax_rate = 0.25

        # Sanity check the fees
        expect(order.adjustments.length).to eq 2
        expect(item_num).to eq 2
        expect(order.adjustment_total).to eq expected_fees
        expect(order.shipment.adjustment.included_tax).to eq 1.2

        allow(subject).to receive(:spree_current_user) { order.user }
        allow(subject).to receive(:order_to_update) { order }
      end

      it "updates the fees" do
        # Setting quantity of an item to zero
        spree_post :update, params

        # Check if fees got updated
        order.reload
        expect(order.line_items.count).to eq 1
        expect(order.adjustment_total).to eq expected_fees - shipping_fee - payment_fee
        expect(order.shipment.adjustment.included_tax).to eq 0.6
      end
    end

    context "with enterprise fees" do
      let(:user) { create(:user) }
      let(:variant) { create(:variant) }
      let(:distributor) { create(:distributor_enterprise, allow_order_changes: true) }
      let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
      let(:enterprise_fee) { create(:enterprise_fee, calculator: build(:calculator_per_item) ) }
      let!(:exchange) { create(:exchange, incoming: true, sender: variant.product.supplier, receiver: order_cycle.coordinator, variants: [variant], enterprise_fees: [enterprise_fee]) }
      let!(:order) do
        order = create(:completed_order_with_totals, user: user, distributor: distributor, order_cycle: order_cycle)
        order.reload.line_items.first.update_attributes(variant_id: variant.id)
        while !order.completed? do break unless order.next! end
        order.update_distribution_charge!
        order
      end
      let(:params) { { order: { line_items_attributes: {
        "0" => { id: order.line_items.first.id, quantity: 2 }
      } } } }

      before do
        allow(subject).to receive(:spree_current_user) { order.user }
        allow(subject).to receive(:order_to_update) { order }
      end

      it "updates the fees" do
        expect(order.reload.adjustment_total).to eq enterprise_fee.calculator.preferred_amount

        allow(controller).to receive_messages spree_current_user: user
        spree_post :update, params

        expect(order.reload.adjustment_total).to eq enterprise_fee.calculator.preferred_amount * 2
      end
    end
  end

  describe "removing items from a completed order" do
    let(:order) { create(:completed_order_with_totals) }
    let!(:line_item) { order.reload.line_items.first }
    let(:params) { { order: {} } }

    before { allow(subject).to receive(:order_to_update) { order } }

    context "when more than one item remains" do
      before do
        params[:order][:line_items_attributes] = { "0" => {quantity: "1", id: line_item.id} }
      end

      it "removes the item" do
        spree_post :update, params
        expect(flash[:error]).to be nil
        expect(response).to redirect_to spree.order_path(order)
        expect(order.reload.line_items.count).to eq 1
      end
    end

    context "when only one item remains" do
      before do
        params[:order][:line_items_attributes] = { "0" => {quantity: "0", id: line_item.id} }
      end

      it "does not remove the item, flash suggests cancellation" do
        spree_post :update, params
        expect(flash[:error]).to eq I18n.t(:orders_cannot_remove_the_final_item)
        expect(response).to redirect_to spree.order_path(order)
        expect(order.reload.line_items.count).to eq 1
      end
    end
  end

  describe "#order_to_update" do
    let!(:current_order) { double(:current_order) }
    let(:params) { { } }

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
        params.merge!({id: order.number})
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
              order.update_attributes!(order_cycle_id: order_cycle.id, distributor_id: distributor.id)
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
      it "responds with unauthorized" do
        spree_put :cancel, params
        expect(response).to render_template 'shared/unauthorized'
      end
    end

    context "when the user has permission to cancel the order" do
      before { allow(controller).to receive(:spree_current_user) { user } }

      context "when the order is not yet complete" do
        it "responds with forbidden" do
          spree_put :cancel, params
          expect(response.status).to redirect_to spree.order_path(order)
          expect(flash[:error]).to eq I18n.t(:orders_could_not_cancel)
        end
      end

      context "when the order is complete" do
        let(:order) { create(:completed_order_with_totals, user: user) }

        before do
          Spree::MailMethod.create!(
            environment: Rails.env,
            preferred_mails_from: 'spree@example.com'
          )
        end

        it "responds with success" do
          spree_put :cancel, params
          expect(response.status).to redirect_to spree.order_path(order)
          expect(flash[:success]).to eq I18n.t(:orders_your_order_has_been_cancelled)
        end
      end
    end
  end


  private

  def num_items_in_cart
    Spree::Order.last.andand.line_items.andand.count || 0
  end
end
