require 'spec_helper'

describe Calculator::Weight do
  it "computes shipping cost for an order by total weight" do
    variant1 = double(:variant, weight: 10)
    variant2 = double(:variant, weight: 20)
    variant3 = double(:variant, weight: nil)

    line_item1 = double(:line_item, variant: variant1, quantity: 1)
    line_item2 = double(:line_item, variant: variant2, quantity: 3)
    line_item3 = double(:line_item, variant: variant3, quantity: 5)

    order = double(:order, line_items: [line_item1, line_item2, line_item3])

    subject.set_preference(:per_kg, 10)
    expect(subject.compute(order)).to eq((10 * 1 + 20 * 3) * 10)
  end

  it "computes shipping cost for a line item" do
    variant = double(:variant, weight: 10)

    line_item = double(:line_item, variant: variant, quantity: 2)

    subject.set_preference(:per_kg, 10)
    expect(subject.compute(line_item)).to eq(10 * 2 * 10)
  end

  it "computes shipping cost for an object with an order" do
    variant1 = double(:variant, weight: 10)
    variant2 = double(:variant, weight: 5)

    line_item1 = double(:line_item, variant: variant1, quantity: 1)
    line_item2 = double(:line_item, variant: variant2, quantity: 2)

    order = double(:order, line_items: [line_item1, line_item2])
    object_with_order = double(:object_with_order, order: order)

    subject.set_preference(:per_kg, 10)
    expect(subject.compute(object_with_order)).to eq((10 * 1 + 5 * 2) * 10)
  end
end
