# frozen_string_literal: true

require "spec_helper"

describe "spree/orders/edit.html.haml" do
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
    it "displays unit prices informations if feature toggle is activated" do
      allow(OpenFoodNetwork::FeatureToggle)
        .to receive(:enabled?).with(:unit_price, anything) { true }
      render
      expect(rendered).to have_selector(".unit-price")
    end
    
    it "not displays unit prices informations if feature toggle is desactivated" do
      allow(OpenFoodNetwork::FeatureToggle)
        .to receive(:enabled?).with(:unit_price, anything) { false }
      render
      expect(rendered).not_to have_selector(".unit-price")
    end
  end
end
