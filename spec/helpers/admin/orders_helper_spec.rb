# frozen_string_literal: true

require "spec_helper"

describe Admin::OrdersHelper, type: :helper do
  describe "#order_adjustments_for_display" do
    let(:order) { create(:order) }

    it "selects eligible adjustments" do
      adjustment = create(:adjustment, adjustable: order, amount: 1)

      expect(helper.order_adjustments_for_display(order)).to eq [adjustment]
    end

    it "filters shipping method adjustments" do
      create(:adjustment, adjustable: order, amount: 1, adjustable_type: "Spree::Shipment")

      expect(helper.order_adjustments_for_display(order)).to eq []
    end
  end
end
