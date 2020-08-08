# frozen_string_literal: true

require 'spec_helper'
describe Spree::Order do
  let(:order) { Spree::Order.new }

  context "clear_adjustments" do
    let(:adjustment) { double("Adjustment") }

    it "destroys all order adjustments" do
      allow(order).to receive_messages(adjustments: adjustment)
      expect(adjustment).to receive(:destroy_all)
      order.clear_adjustments!
    end

    it "destroy all line item adjustments" do
      allow(order).to receive_messages(line_item_adjustments: adjustment)
      expect(adjustment).to receive(:destroy_all)
      order.clear_adjustments!
    end
  end

  context "totaling adjustments" do
    let(:adjustment1) { build(:adjustment, amount: 5) }
    let(:adjustment2) { build(:adjustment, amount: 10) }

    context "#ship_total" do
      it "should return the correct amount" do
        allow(order).to receive_message_chain :adjustments, shipping: [adjustment1, adjustment2]
        expect(order.ship_total).to eq 15
      end
    end

    context "#tax_total" do
      it "should return the correct amount" do
        allow(order).to receive_message_chain :adjustments, tax: [adjustment1, adjustment2]
        expect(order.tax_total).to eq 15
      end
    end
  end

  context "line item adjustment totals" do
    before { @order = Spree::Order.create! }

    context "when there are no line item adjustments" do
      before { allow(@order).to receive_message_chain(:line_item_adjustments, eligible: []) }

      it "should return an empty hash" do
        expect(@order.line_item_adjustment_totals).to eq({})
      end
    end

    context "when there are two adjustments with different labels" do
      let(:adj1) { build(:adjustment, amount: 10, label: "Foo") }
      let(:adj2) { build(:adjustment, amount: 20, label: "Bar") }

      before do
        allow(@order).to receive_message_chain(:line_item_adjustments, eligible: [adj1, adj2])
      end

      it "should return exactly two totals" do
        expect(@order.line_item_adjustment_totals.size).to eq 2
      end

      it "should return the correct totals" do
        expect(@order.line_item_adjustment_totals["Foo"]).to eq Spree::Money.new(10)
        expect(@order.line_item_adjustment_totals["Bar"]).to eq Spree::Money.new(20)
      end
    end

    context "when there are two adjustments with one label and a single adjustment with another" do
      let(:adj1) { build(:adjustment, amount: 10, label: "Foo") }
      let(:adj2) { build(:adjustment, amount: 20, label: "Bar") }
      let(:adj3) { build(:adjustment, amount: 40, label: "Bar") }

      before do
        allow(@order).to receive_message_chain(:line_item_adjustments, eligible: [adj1, adj2, adj3])
      end

      it "should return exactly two totals" do
        expect(@order.line_item_adjustment_totals.size).to eq 2
      end
      it "should return the correct totals" do
        expect(@order.line_item_adjustment_totals["Foo"]).to eq Spree::Money.new(10)
        expect(@order.line_item_adjustment_totals["Bar"]).to eq Spree::Money.new(60)
      end
    end
  end

  context "line item adjustments" do
    before do
      @order = Spree::Order.create!
      allow(@order).to receive_messages line_items: [line_item1, line_item2]
    end

    let(:line_item1) { create(:line_item, order: @order) }
    let(:line_item2) { create(:line_item, order: @order) }

    context "when there are no line item adjustments" do
      it "should return nothing if line items have no adjustments" do
        expect(@order.line_item_adjustments).to be_empty
      end
    end

    context "when only one line item has adjustments" do
      before do
        @adj1 = line_item1.adjustments.create(
          amount: 2,
          source: line_item1,
          label: "VAT 5%"
        )

        @adj2 = line_item1.adjustments.create(
          amount: 5,
          source: line_item1,
          label: "VAT 10%"
        )
      end

      it "should return the adjustments for that line item" do
        expect(@order.line_item_adjustments).to include @adj1
        expect(@order.line_item_adjustments).to include @adj2
      end
    end

    context "when more than one line item has adjustments" do
      before do
        @adj1 = line_item1.adjustments.create(
          amount: 2,
          source: line_item1,
          label: "VAT 5%"
        )

        @adj2 = line_item2.adjustments.create(
          amount: 5,
          source: line_item2,
          label: "VAT 10%"
        )
      end

      it "should return the adjustments for each line item" do
        expect(@order.line_item_adjustments).to include @adj1
        expect(@order.line_item_adjustments).to include @adj2
      end
    end
  end
end
