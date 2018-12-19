require 'spec_helper'

describe VariantsStockLevels do
  let(:order) { create(:order) }

  let!(:line_item) { create(:line_item, order: order, variant: variant_in_the_order, quantity: 2, max_quantity: 3) }
  let!(:variant_in_the_order) { create(:variant, count_on_hand: 4) }
  let!(:variant_not_in_the_order) { create(:variant, count_on_hand: 2) }

  let(:variant_stock_levels) { VariantsStockLevels.new }

  before do
    order.reload
  end

  it "returns a hash with variant id, quantity, max_quantity and stock on hand" do
    expect(variant_stock_levels.call(order, [variant_in_the_order.id])).to eq(
      variant_in_the_order.id => { quantity: 2, max_quantity: 3, on_hand: 4 }
    )
  end

  it "includes all line items, even when the variant_id is not specified" do
    expect(variant_stock_levels.call(order, [])).to eq(
      variant_in_the_order.id => { quantity: 2, max_quantity: 3, on_hand: 4 }
    )
  end

  it "includes an empty quantity entry for variants that aren't in the order" do
    expect(variant_stock_levels.call(order, [variant_in_the_order.id, variant_not_in_the_order.id])).to eq(
      variant_in_the_order.id => { quantity: 2, max_quantity: 3, on_hand: 4 },
      variant_not_in_the_order.id => { quantity: 0, max_quantity: 0, on_hand: 2 }
    )
  end

  describe "encoding Infinity" do
    let!(:variant_in_the_order) { create(:variant, on_demand: true, count_on_hand: 0) }

    it "encodes Infinity as a large, finite integer" do
      expect(variant_stock_levels.call(order, [variant_in_the_order.id])).to eq(
        variant_in_the_order.id => { quantity: 2, max_quantity: 3, on_hand: 2147483647 }
      )
    end
  end
end
