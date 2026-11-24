# frozen_string_literal: true

RSpec.describe "Orders" do
  let(:user) { create(:user) }
  let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
  let(:order) {
    create(:completed_order_with_totals, user:, line_items_count: 2, distributor:, order_cycle:)
  }
  let(:first_item) { order.line_items.first }
  let(:second_item) { order.line_items.second }

  describe "PATCH /orders/:id" do
    before { sign_in user }

    # Like the order page, sends every line item: the ones not given keep their quantity.
    def update_quantities(new_quantities)
      line_items_attributes = order.line_items.each_with_index.to_h do |line_item, index|
        quantity = new_quantities.fetch(line_item, line_item.quantity)
        [index.to_s, { id: line_item.id, quantity: }]
      end

      patch order_path(order), params: { order: { line_items_attributes: } }
    end

    context "when the shop only allows items to be added" do
      let(:distributor) { create(:distributor_enterprise, allow_order_additions: true) }

      it "raises a quantity" do
        expect { update_quantities(first_item => first_item.quantity + 1) }
          .to change { first_item.reload.quantity }.by(1)

        expect(response).to redirect_to order_path(order)
        expect(flash[:error]).to be_nil
      end

      it "doesn't remove an item" do
        update_quantities(first_item => 0)

        expect(response).to redirect_to order_path(order)
        expect(flash[:error]).to eq "Sorry, the shop doesn't allow this change to your order."
        expect(order.reload.line_items.count).to eq 2
      end
    end

    context "when the shop only allows items to be removed" do
      let(:distributor) { create(:distributor_enterprise, allow_order_removals: true) }

      it "removes an item" do
        update_quantities(first_item => 0)

        expect(response).to redirect_to order_path(order)
        expect(flash[:error]).to be_nil
        expect(order.reload.line_items.count).to eq 1
      end

      it "keeps the last item and suggests cancelling the order instead" do
        update_quantities(first_item => 0, second_item => 0)

        expect(response).to redirect_to order_path(order)
        expect(flash[:error])
          .to eq "Cannot remove the final item from an order, please cancel the order instead."
        expect(order.reload.line_items.count).to eq 2
      end

      it "doesn't raise a quantity" do
        expect { update_quantities(first_item => first_item.quantity + 1) }
          .not_to change { first_item.reload.quantity }

        expect(response).to redirect_to order_path(order)
        expect(flash[:error]).to eq "Sorry, the shop doesn't allow this change to your order."
      end
    end
  end

  describe "PUT /orders/:id/cancel" do
    context "when the shop allows orders to be cancelled" do
      let(:distributor) { create(:distributor_enterprise, allow_order_cancellation: true) }

      it "cancels the customer's own order" do
        sign_in user

        put cancel_order_path(order)

        expect(flash[:success]).to eq "Your order has been cancelled"
        expect(order.reload).to be_canceled
      end

      it "cancels a guest's order using the order's token" do
        order.update!(user: nil, email: "guest@example.com")
        # The order confirmation link stores the token in the session.
        get order_path(order, order_token: order.token)

        put cancel_order_path(order)

        expect(flash[:success]).to eq "Your order has been cancelled"
        expect(order.reload).to be_canceled
      end

      it "doesn't cancel someone else's order" do
        sign_in create(:user)

        put cancel_order_path(order)

        expect(response).to redirect_to unauthorized_path
        expect(order.reload).to be_complete
      end

      it "doesn't cancel an order that isn't placed yet" do
        cart = create(:order, user:, distributor:, order_cycle:)
        sign_in user

        put cancel_order_path(cart)

        expect(response).to redirect_to unauthorized_path
        expect(cart.reload).to be_cart
      end

      it "doesn't cancel the order once the order cycle has closed" do
        order_cycle.update!(orders_close_at: 1.minute.ago)
        sign_in user

        put cancel_order_path(order)

        expect(response).to redirect_to unauthorized_path
        expect(order.reload).to be_complete
      end
    end

    context "when the shop allows other changes but not cancelling" do
      let(:distributor) {
        create(:distributor_enterprise, allow_order_additions: true, allow_order_removals: true)
      }

      it "doesn't cancel the order" do
        sign_in user

        put cancel_order_path(order)

        expect(response).to redirect_to unauthorized_path
        expect(order.reload).to be_complete
      end
    end
  end
end
