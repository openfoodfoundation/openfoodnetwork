# frozen_string_literal: true

RSpec.describe "spree/orders/edit.html.haml" do
  helper InjectionHelper
  helper ShopHelper
  helper ApplicationHelper
  helper CheckoutHelper
  helper LinkHelper
  helper SharedHelper
  helper FooterLinksHelper
  helper MarkdownHelper
  helper TermsAndConditionsHelper

  let(:order) { create(:completed_order_with_fees) }

  before do
    assign(:order, order)
    assign(:insufficient_stock_lines, [])
    allow(view).to receive_messages(
      order:,
      current_order: order,
      pickup_time: 'time',
      spree_current_user: create(:user),
    )
  end

  describe "unit prices" do
    it "displays unit prices informations" do
      render
      expect(rendered).to have_selector(".unit-price")
    end
  end

  describe "display adjustments" do
    let(:voucher) { create(:voucher, enterprise: order.distributor) }

    before do
      voucher.create_adjustment(voucher.code, order)
      OrderManagement::Order::Updater.new(order).update_voucher
      render
    end

    it "includes Voucher text with label" do
      expect(rendered).to have_content("Voucher:\n#{voucher.code}")
    end

    # Shipping fee is derived from 'completed_order_with_fees' factory.
    # It applies when using shipping method such as Home Delivery.
    it "includes Shipping label" do
      expect(rendered).to have_content("Shipping")
    end

    # Transaction fee is derived from 'completed_order_with_fees' factory.
    # It applies when using payment methods such as Check & Stripe.
    it "includes Transaction fee label" do
      expect(rendered).to have_content("Transaction fee")
    end
  end
end
