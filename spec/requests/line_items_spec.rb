# frozen_string_literal: true

RSpec.describe "Line items" do
  let(:user) { create(:user) }
  let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
  let(:order) {
    create(:completed_order_with_totals, user:, line_items_count: 2, distributor:, order_cycle:)
  }
  let(:line_item) { order.line_items.first }

  before { sign_in user }

  describe "DELETE /line_items/:id" do
    context "when the shop allows items to be removed" do
      let(:distributor) { create(:distributor_enterprise, allow_order_removals: true) }

      it "removes the item from the order" do
        delete line_item_path(line_item, format: :json)

        expect(response).to have_http_status :no_content
        expect(order.reload.line_items).not_to include line_item
      end

      it "leaves credit owed on an order that was already paid" do
        payment = create(:check_payment, :completed, amount: order.total, order:)
        payment.capture!
        expect(order.reload.payment_state).to eq "paid"

        delete line_item_path(line_item, format: :json)

        expect(order.reload.payment_state).to eq "credit_owed"
      end

      it "doesn't remove an item from someone else's order" do
        order.update!(user: create(:user))

        delete line_item_path(line_item, format: :json)

        expect(response).to have_http_status :forbidden
        expect(order.reload.line_items).to include line_item
      end

      it "doesn't remove an item from an order without an order cycle" do
        # Validations stop this being saved normally, but older orders can lack an order cycle.
        order.update_columns(order_cycle_id: nil)

        delete line_item_path(line_item, format: :json)

        expect(response).to have_http_status :forbidden
        expect(order.reload.line_items).to include line_item
      end
    end

    context "when the shop allows other changes but not removing items" do
      let(:distributor) {
        create(:distributor_enterprise, allow_order_additions: true, allow_order_cancellation: true)
      }

      it "keeps the item in the order" do
        delete line_item_path(line_item, format: :json)

        expect(response).to have_http_status :forbidden
        expect(order.reload.line_items).to include line_item
      end
    end

    context "when the shop doesn't allow any changes" do
      let(:distributor) { create(:distributor_enterprise) }

      it "keeps the item in the order" do
        delete line_item_path(line_item, format: :json)

        expect(response).to have_http_status :forbidden
        expect(order.reload.line_items).to include line_item
      end
    end
  end
end
