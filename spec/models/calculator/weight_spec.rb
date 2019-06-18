require 'spec_helper'

describe Calculator::Weight do
  it_behaves_like "a model using the LocalizedNumber module", [:preferred_per_kg]

  it "computes shipping cost for an order by total weight" do
    variant1 = build(:variant, weight: 10)
    variant2 = build(:variant, weight: 20)
    variant3 = build(:variant, weight: nil)

    line_item1 = build(:line_item, variant: variant1, quantity: 1)
    line_item2 = build(:line_item, variant: variant2, quantity: 3)
    line_item3 = build(:line_item, variant: variant3, quantity: 5)

    order = double(:order, line_items: [line_item1, line_item2, line_item3])

    subject.set_preference(:per_kg, 10)
    expect(subject.compute(order)).to eq((10 * 1 + 20 * 3) * 10)
  end

  describe "line item with variant weight" do
    let(:variant) { build(:variant, weight: 10) }
    let(:line_item) { build(:line_item, variant: variant, quantity: 2) }

    before { subject.set_preference(:per_kg, 10) }

    it "computes shipping cost for a line item" do
      expect(subject.compute(line_item)).to eq(10 * 2 * 10)
    end

    describe "and with final_weight_volume defined" do
      before { line_item.update_attribute :final_weight_volume, '18000' }

      it "computes fee using final_weight_volume, not the variant weight" do
        expect(subject.compute(line_item)).to eq(10 * 18)
      end

      it "returns zero for variant where unit type is not weight" do
        line_item.variant.product.update_attribute :variant_unit, 'items'
        expect(subject.compute(line_item)).to eq(0)
      end
    end
  end

  it "computes shipping cost for an object with an order" do
    variant1 = build(:variant, weight: 10)
    variant2 = build(:variant, weight: 5)

    line_item1 = build(:line_item, variant: variant1, quantity: 1)
    line_item2 = build(:line_item, variant: variant2, quantity: 2)

    order = double(:order, line_items: [line_item1, line_item2])
    object_with_order = double(:object_with_order, order: order)

    subject.set_preference(:per_kg, 10)
    expect(subject.compute(object_with_order)).to eq((10 * 1 + 5 * 2) * 10)
  end
end
