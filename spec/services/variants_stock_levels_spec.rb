require 'spec_helper'

describe VariantsStockLevels do
  let(:order) { create(:order) }

  let!(:line_item) do
    create(:line_item, order: order, variant: variant_in_the_order, quantity: 2, max_quantity: 3)
  end
  let!(:variant_in_the_order) { create(:variant) }
  let!(:variant_not_in_the_order) { create(:variant) }

  let(:variant_stock_levels) { VariantsStockLevels.new }

  before do
    variant_in_the_order.on_hand = 4
    variant_not_in_the_order.on_hand = 2
    order.reload
  end

  it "returns a hash with variant id, quantity, max_quantity, on hand and on demand" do
    expect(variant_stock_levels.call(order, [variant_in_the_order.id])).to eq(
      variant_in_the_order.id => { quantity: 2, max_quantity: 3, on_hand: 4, on_demand: false }
    )
  end

  it "includes all line items, even when the variant_id is not specified" do
    expect(variant_stock_levels.call(order, [])).to eq(
      variant_in_the_order.id => { quantity: 2, max_quantity: 3, on_hand: 4, on_demand: false }
    )
  end

  it "includes an empty quantity entry for variants that aren't in the order" do
    variant_ids = [variant_in_the_order.id, variant_not_in_the_order.id]
    expect(variant_stock_levels.call(order, variant_ids)).to eq(
      variant_in_the_order.id => { quantity: 2, max_quantity: 3, on_hand: 4, on_demand: false },
      variant_not_in_the_order.id => { quantity: 0, max_quantity: 0, on_hand: 2, on_demand: false }
    )
  end

  describe "when variant is on_demand" do
    let!(:variant_in_the_order) { create(:variant, on_demand: true) }

    before { variant_in_the_order.on_hand = 0 }

    it "includes the actual on_hand value and on_demand: true" do
      expect(variant_stock_levels.call(order, [variant_in_the_order.id])).to eq(
        variant_in_the_order.id => { quantity: 2, max_quantity: 3, on_hand: 0, on_demand: true }
      )
    end
  end
end
