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
      create(:adjustment, adjustable: order, amount: 1, originator_type: "Spree::ShippingMethod")

      expect(helper.order_adjustments_for_display(order)).to eq []
    end

    it "filters zero tax rate adjustments" do
      create(:adjustment, adjustable: order, amount: 0, originator_type: "Spree::TaxRate")

      expect(helper.order_adjustments_for_display(order)).to eq []
    end
  end
end
