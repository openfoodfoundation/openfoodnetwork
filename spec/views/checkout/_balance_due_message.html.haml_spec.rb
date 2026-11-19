# frozen_string_literal: true

RSpec.describe "checkout/_balance_due_message.html.haml" do
  let(:distributor) { create(:distributor_enterprise) }
  let(:customer) { create(:customer, enterprise: distributor) }
  let(:order) { create(:order_with_line_items, line_items_count: 1, distributor:, customer:) }
  let(:previous_order) { create(:order, distributor:, customer:) }

  before do
    assign(:order, order)
  end

  context "when a balance has been carried over to the order" do
    before do
      payment = create(:payment, order: previous_order, amount: 0.57, state: "completed")
      create(:customer_account_transaction, customer:, amount: -0.57, payment:)
      Orders::BalanceDueService.new(order).apply
    end

    it "explains the balance due and links to the previous order in a new tab" do
      render

      expect(rendered).to have_content(
        "$0.57 balance due from order(s) #{previous_order.number} has been added to this order."
      )
      expect(rendered).to have_link(previous_order.number, href: "/orders/#{previous_order.number}")
      expect(rendered).to have_css("a[target='_blank'][rel='noopener']")
    end
  end

  context "when no balance has been carried over" do
    it "renders nothing" do
      render

      expect(rendered).to be_blank
    end
  end
end
