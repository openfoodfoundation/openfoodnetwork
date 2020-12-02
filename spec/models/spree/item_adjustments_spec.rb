# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe ItemAdjustments do
    let(:order) { create(:order_with_line_items, line_items_count: 1) }
    let(:line_item) { order.line_items.first }

    let(:subject) { ItemAdjustments.new(line_item) }

    context '#update' do
      it "updates a linked adjustment" do
        tax_rate = create(:tax_rate, amount: 0.05)
        adjustment = create(:adjustment, source: tax_rate, adjustable: line_item)
        line_item.price = 10
        line_item.tax_category = tax_rate.tax_category

        subject.update
        expect(line_item.adjustment_total).to eq 0.5
        expect(line_item.tax_total).to eq 0.5
      end
    end
  end
end
