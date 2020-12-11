# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe ItemAdjustments do
    let(:order) { create(:order_with_line_items, line_items_count: 1) }
    let(:line_item) { order.line_items.first }
    let(:tax_rate) { create(:tax_rate, amount: 0.05) }


    let(:subject) { ItemAdjustments.new(line_item) }

    context '#update' do
      it "updates a linked adjustment" do
        adjustment = create(:adjustment, source: tax_rate, adjustable: line_item)
        line_item.price = 10
        line_item.tax_category = tax_rate.tax_category

        subject.update
        expect(line_item.included_tax_total).to eq 0
        expect(line_item.additional_tax_total).to eq 0.5
        expect(line_item.adjustment_total).to eq 0.5
      end
    end

    context "tax included in price" do
      before do
        create(:adjustment,
               source: tax_rate,
               adjustable: line_item,
               included: true
        )
      end

      it "tax has no bearing on final price" do
        subject.update_adjustments
        line_item.reload
        expect(line_item.included_tax_total).to eq 0.5
        expect(line_item.additional_tax_total).to eq 0
        expect(line_item.adjustment_total).to eq 0
      end
    end

    context "tax excluded from price" do
      before do
        create(:adjustment,
               source: tax_rate,
               adjustable: line_item,
               included: false
        )
      end

      it "tax applies to line item" do
        subject.update_adjustments
        line_item.reload
        expect(line_item.included_tax_total).to eq 0
        expect(line_item.additional_tax_total).to eq 0.5
        expect(line_item.adjustment_total).to eq 0.5
      end
    end

    # For Spree #4483
    context "callbacks" do
      class SuperItemAdjustments < Spree::ItemAdjustments
        attr_accessor :before_tax_adjustments_called,
                      :after_tax_adjustments_called

        set_callback :tax_adjustments, :before do |object|
          @before_tax_adjustments_called = true
        end

        set_callback :tax_adjustments, :after do |object|
          @after_tax_adjustments_called = true
        end
      end
      let(:subject) { SuperItemAdjustments.new(line_item) }

      it "calls all the callbacks" do
        subject.update_adjustments
        expect(subject.before_tax_adjustments_called).to be_truthy
        expect(subject.after_tax_adjustments_called).to be_truthy
      end
    end
  end
end
