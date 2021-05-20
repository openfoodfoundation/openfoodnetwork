# frozen_string_literal: true

require "spec_helper"

describe "spree/orders/edit.html.haml" do
  helper InjectionHelper
  helper ShopHelper
  helper ApplicationHelper
  helper CheckoutHelper
  helper SharedHelper
  helper FooterLinksHelper
  helper MarkdownHelper
  helper TermsAndConditionsHelper

  let(:order) { create(:completed_order_with_fees) }

  before do
    assign(:order, order)
    assign(:insufficient_stock_lines, [])
    allow(view).to receive_messages(
      order: order,
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
end
