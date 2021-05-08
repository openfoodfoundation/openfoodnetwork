# frozen_string_literal: true

require 'spec_helper'

describe Spree::Order do
  let(:order) { Spree::Order.new }

  context "totaling adjustments" do
    let!(:adjustment1) { create(:adjustment, amount: 5) }
    let!(:adjustment2) { create(:adjustment, amount: 10) }
    let(:adjustments) { Spree::Adjustment.where(id: [adjustment1, adjustment2]) }

    context "#ship_total" do
      it "should return the correct amount" do
        allow(order).to receive_message_chain :all_adjustments, shipping: adjustments
        expect(order.ship_total).to eq 15
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
          label: "VAT 5%"
        )

        @adj2 = line_item1.adjustments.create(
          amount: 5,
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
          label: "VAT 5%"
        )

        @adj2 = line_item2.adjustments.create(
          amount: 5,
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
