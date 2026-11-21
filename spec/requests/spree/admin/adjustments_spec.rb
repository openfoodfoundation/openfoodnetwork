# frozen_string_literal: true

RSpec.describe Spree::Admin::AdjustmentsController do
  let(:order) { create(:completed_order_with_totals) }
  let(:customer) { create(:customer, enterprise: order.distributor) }
  let!(:balance_due) {
    create(:adjustment, adjustable: order, order:, originator: customer, amount: 0.57,
                        label: "Balance due from previous order(s) R123", state: "finalized")
  }

  before do
    login_as create(:admin_user)
  end

  describe "PUT /admin/orders/:order_id/adjustments/:id" do
    it "doesn't change a balance due carried over from a previous order" do
      put admin_order_adjustment_path(order, balance_due),
          params: { adjustment: { label: "Changed", amount: "0.00" } }

      expect(balance_due.reload.amount).to eq(0.57)
      expect(response).to redirect_to(admin_order_adjustments_path(order))
      expect(flash[:error]).to eq(
        "A balance due carried over from a previous order can't be changed. " \
        "Use 'Add credit' on the Customers page to waive it."
      )
    end
  end

  describe "DELETE /admin/orders/:order_id/adjustments/:id" do
    it "doesn't delete a balance due carried over from a previous order" do
      expect {
        delete admin_order_adjustment_path(order, balance_due)
      }.not_to change { Spree::Adjustment.count }

      expect(response).to redirect_to(admin_order_adjustments_path(order))
    end
  end
end
