# frozen_string_literal: true

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

  describe "#update_line_items" do
    context "with no variant out of stock" do
      it "returns an empty array" do
        expect(subject.update_line_items).to be_empty
      end
    end

    context "with no variant with reduced stock" do
      it "returns an empty array" do
        expect(subject.update_line_items).to be_empty
      end
    end

    context "with a variant out of stock" do
      let(:variant) { order.line_items.first.variant }

      before do
        variant.update!(on_demand: false, on_hand: 0)
      end

      it "removes the machting line item" do
        subject.update_line_items

        expect(order.line_items.reload.select { |li| li.variant == variant }).to be_empty
      end

      it "returns an array including the out of stock variant" do
        expect(subject.update_line_items).to eq([variant])
      end
    end

    context "with a variant with reduced stock" do
      let(:line_item) { order.line_items.last }
      let(:variant) { line_item.variant }

      before do
        order.contents.add(variant, 2)
        variant.update!(on_demand: false, on_hand: 1)
      end

      it "updates the machting line item quantity" do
        subject.update_line_items

        expect(line_item.reload.quantity).to be(1)
      end

      it "returns an array including the reduced stock variant" do
        expect(subject.update_line_items).to eq([variant])
      end
    end

    context "with a variant with reduced stock and a variant out of stock" do
      let(:line_item_out_of_stock) { order.line_items.last }
      let(:variant_out_of_stock) { line_item_out_of_stock.variant }
      let(:line_item_reduced_stock) { order.line_items.first }
      let(:variant_reduced_stock) { line_item_reduced_stock.variant }

      before do
        variant_out_of_stock.update!(on_demand: false, on_hand: 0)
        order.contents.add(variant_reduced_stock, 3)
        variant_reduced_stock.update!(on_demand: false, on_hand: 2)
      end

      it "removes the line item matching the out of stock variant" do
        subject.update_line_items

        expect(order.line_items).not_to include(line_item_out_of_stock)
      end

      it "updates the line item quantity matching the reduced stock variant" do
        subject.update_line_items

        expect(line_item_reduced_stock.reload.quantity).to eq(2)
      end

      it "returns an array including the out of stock variant and thereduced stock variant" do
        expect(subject.update_line_items).to include(variant_out_of_stock, variant_reduced_stock)
      end
    end
  end
end
