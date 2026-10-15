# frozen_string_literal: true

RSpec.describe ViewData::CartItem do
  describe ".index" do
    it "indexes cart items by variant id" do
      line_items = [
        Spree::LineItem.new(variant_id: 1, quantity: 2),
        Spree::LineItem.new(variant_id: 2, quantity: 3, max_quantity: 5),
      ]

      index = described_class.index(line_items)

      expect(index.keys).to eq [1, 2]
      expect(index[1]).to eq described_class.new(quantity: 2, max_quantity: nil)
      expect(index[2]).to eq described_class.new(quantity: 3, max_quantity: 5)
    end

    it "returns an empty cart item for a variant not in the cart" do
      index = described_class.index([Spree::LineItem.new(variant_id: 1, quantity: 2)])

      expect(index[99]).to eq described_class.empty
    end

    it "doesn't add a key when looking up a variant not in the cart" do
      index = described_class.index([])

      index[99]

      expect(index).to be_empty
    end
  end
end
