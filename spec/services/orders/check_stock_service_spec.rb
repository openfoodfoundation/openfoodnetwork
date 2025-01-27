# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Orders::CheckStockService do
  subject { described_class.new(order:) }

  let(:order) { create(:order_with_line_items) }

  describe "#sufficient_stock?" do
    it "returns true if enough stock" do
      expect(subject.sufficient_stock?).to be(true)
    end

    context "when one or more item are out of stock" do
      it "returns false" do
        variant = order.line_items.first.variant
        variant.update!(on_demand: false, on_hand: 0)

        expect(subject.sufficient_stock?).to be(false)
      end
    end
  end
end
