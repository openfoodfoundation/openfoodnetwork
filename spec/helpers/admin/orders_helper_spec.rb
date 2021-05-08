# frozen_string_literal: true

require "spec_helper"

describe Admin::OrdersHelper, type: :helper do
  describe "#order_adjustments_for_display" do
    let(:order) { create(:order) }

    it "selects eligible adjustments" do
      adjustment = create(:adjustment, order: order, adjustable: order, amount: 1)

      expect(helper.order_adjustments_for_display(order)).to eq [adjustment]
    end

    it "filters shipping method adjustments" do
      create(:adjustment, order: order, adjustable: build(:shipment), amount: 1,
                          originator_type: "Spree::ShippingMethod")

      expect(helper.order_adjustments_for_display(order)).to eq []
    end

    it "filters ineligible payment adjustments" do
      create(:adjustment, adjustable: build(:payment), amount: 0, eligible: false,
                          originator_type: "Spree::PaymentMethod", order: order)

      expect(helper.order_adjustments_for_display(order)).to eq []
    end

    it "filters out line item adjustments" do
      create(:adjustment, adjustable: build(:line_item), amount: 0, eligible: false,
                          originator_type: "EnterpriseFee", order: order)

      expect(helper.order_adjustments_for_display(order)).to eq []
    end
  end
end
