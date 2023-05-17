# frozen_string_literal: true

require 'spec_helper'

describe Calculator::Weight do
  it "computes shipping cost for an order by total weight" do
    variant1 = build_stubbed(:variant, unit_value: 10_000)
    variant2 = build_stubbed(:variant, unit_value: 20_000)
    variant3 = build_stubbed(:variant, unit_value: nil)

    line_item1 = build_stubbed(:line_item, variant: variant1, quantity: 1)
    line_item2 = build_stubbed(:line_item, variant: variant2, quantity: 3)
    line_item3 = build_stubbed(:line_item, variant: variant3, quantity: 5)

    order = double(:order, line_items: [line_item1, line_item2, line_item3])

    subject.set_preference(:per_unit, 5)
    subject.set_preference(:unit_from_list, "kg")
    expect(subject.compute(order)).to eq(350) # (10 * 1 + 20 * 3) * 5
  end

  describe "line item with variant_unit weight and variant unit_value" do
    let(:variant) { build_stubbed(:variant, unit_value: 10_000) }
    let(:line_item) { build_stubbed(:line_item, variant: variant, quantity: 2) }

    before {
      subject.set_preference(:per_unit, 5)
      subject.set_preference(:unit_from_list, "kg")
    }

    it "computes shipping cost for a line item" do
      expect(subject.compute(line_item)).to eq(100) # 10 * 2 * 5
    end

    describe "and with final_weight_volume defined" do
      before do
        line_item.final_weight_volume = '18000'
      end

      it "computes fee using final_weight_volume, not the variant weight" do
        expect(subject.compute(line_item)).to eq(90) # 18 * 5
      end

      context "where variant unit is not weight" do
        it "uses both final_weight_volume and weight to calculate fee" do
          line_item.variant.weight = 7
          line_item.variant.product.variant_unit = 'items'
          expect(subject.compute(line_item)).to eq(63) # 7 * (18000/10000) * 5
        end
      end
    end
  end

  it "computes shipping cost for an object with an order" do
    variant1 = build_stubbed(:variant, unit_value: 10_000)
    variant2 = build_stubbed(:variant, unit_value: 20_000)

    line_item1 = build_stubbed(:line_item, variant: variant1, quantity: 1)
    line_item2 = build_stubbed(:line_item, variant: variant2, quantity: 2)

    order = double(:order, line_items: [line_item1, line_item2])
    object_with_order = double(:object_with_order, order: order)

    subject.set_preference(:per_unit, 5)
    subject.set_preference(:unit_from_list, "kg")
    expect(subject.compute(object_with_order)).to eq(250) # (10 * 1 + 20 * 2) * 5
    subject.set_preference(:unit_from_list, "lb")
    expect(subject.compute(object_with_order)).to eq(551.15) # (10 * 1 + 20 * 2) * 5 * 2.2
  end

  context "when line item final_weight_volume is set" do
    let!(:product) { build_stubbed(:product, product_attributes) }
    let!(:variant) { build_stubbed(:variant, variant_attributes.merge(product: product)) }

    let(:calculator) { described_class.new(preferred_per_unit: 6, preferred_unit_from_list: "kg") }
    let(:line_item) do
      build_stubbed(:line_item, variant: variant, quantity: 2).tap do |object|
        object.send(:calculate_final_weight_volume)
      end
    end

    context "when the product uses weight unit" do
      context "when the product is in g (3g)" do
        let!(:product_attributes) { { variant_unit: "weight", variant_unit_scale: 1.0 } }
        let!(:variant_attributes) { { unit_value: 300.0, weight: 0.30 } }

        it "is correct" do
          expect(line_item.final_weight_volume).to eq(600) # 600g
          line_item.final_weight_volume = 700 # 700g
          expect(calculator.compute(line_item)).to eq(4.2) # 0.7 * 6
        end
      end

      context "when the product is in kg (3kg)" do
        let!(:product_attributes) { { variant_unit: "weight", variant_unit_scale: 1_000.0 } }
        let!(:variant_attributes) { { unit_value: 3_000.0, weight: 3.0 } }

        it "is correct" do
          expect(line_item.final_weight_volume).to eq(6_000) # 6kg
          line_item.final_weight_volume = 7_000 # 7kg
          expect(calculator.compute(line_item)).to eq(42) # 7 * 6
        end
      end

      context "when the product is in T (3T)" do
        let!(:product_attributes) { { variant_unit: "weight", variant_unit_scale: 1_000_000.0 } }
        let!(:variant_attributes) { { unit_value: 3_000_000.0, weight: 3_000.0 } }

        it "is correct" do
          expect(line_item.final_weight_volume).to eq(6_000_000) # 6T
          line_item.final_weight_volume = 7_000_000 # 7T
          expect(calculator.compute(line_item)).to eq(42_000) # 7000 * 6
        end
      end

      context "when the product is in lb (1lb)" do
        let!(:product_attributes) { { variant_unit: "weight", variant_unit_scale: 453.6 } }
        let!(:variant_attributes) { { unit_value: 453.6, weight: 453.6 } }

        it "is correct" do
          expect(line_item.final_weight_volume).to eq(907.2) # 2lb
          line_item.final_weight_volume = 680.4 # 1.5lb
          expect(calculator.compute(line_item)).to eq(4.08) # 0.6804 * 6
        end
      end

      context "when the product is in oz (8oz)" do
        let!(:product_attributes) { { variant_unit: "weight", variant_unit_scale: 28.35 } }
        let!(:variant_attributes) { { unit_value: 226.8, weight: 226.8 } }

        it "is correct" do
          expect(line_item.final_weight_volume).to eq(453.6) # 2 * 8oz == 1lb
          line_item.final_weight_volume = 680.4 # 1.5lb
          expect(calculator.compute(line_item)).to eq(4.08) # 0.6804 * 6
        end
      end
    end

    context "when the product uses volume unit" do
      context "when the product is in mL (300mL)" do
        let!(:product_attributes) { { variant_unit: "volume", variant_unit_scale: 0.001 } }
        let!(:variant_attributes) { { unit_value: 0.3, weight: 0.25 } }

        it "is correct" do
          expect(line_item.final_weight_volume).to eq(0.6) # 600mL
          line_item.final_weight_volume = 0.7 # 700mL
          expect(calculator.compute(line_item)).to eq(3.50) # 0.25 * (0.7/0.3) * 6
        end
      end

      context "when the product is in L (3L)" do
        let!(:product_attributes) { { variant_unit: "volume", variant_unit_scale: 1 } }
        let!(:variant_attributes) { { unit_value: 3.0, weight: 2.5 } }

        it "is correct" do
          expect(line_item.final_weight_volume).to eq(6) # 6L
          line_item.final_weight_volume = 7 # 7L
          expect(calculator.compute(line_item)).to eq(35.00) # 2.5 * (7/3) * 6
        end
      end

      context "when the product is in kL (3kL)" do
        let!(:product_attributes) { { variant_unit: "volume", variant_unit_scale: 1_000 } }
        let!(:variant_attributes) { { unit_value: 3_000.0, weight: 2_500.0 } }

        it "is correct" do
          expect(line_item.final_weight_volume).to eq(6_000) # 6kL
          line_item.final_weight_volume = 7_000 # 7kL
          expect(calculator.compute(line_item)).to eq(34_995) # 2_500 * round(7_000/3_000) * 6
        end
      end
    end

    context "when the product uses item unit" do
      let!(:product_attributes) {
        { variant_unit: "items", variant_unit_scale: nil, variant_unit_name: "pc",
          display_as: "pc" }
      }
      let!(:variant_attributes) { { unit_value: 3.0, weight: 2.5, display_as: "pc" } }

      it "is correct" do
        expect(line_item.final_weight_volume).to eq(6) # 6 pcs
        line_item.final_weight_volume = 7 # 7 pcs
        expect(calculator.compute(line_item)).to eq(35.0) # 2.5 * (7/3) * 6
      end
    end
  end

  context "when variant_unit is 'items'" do
    let(:product) {
      build_stubbed(:product, variant_unit: 'items', variant_unit_scale: nil,
                              variant_unit_name: "bunch")
    }
    let(:line_item) { build_stubbed(:line_item, variant: variant, quantity: 1) }

    before {
      subject.set_preference(:per_unit, 5)
      subject.set_preference(:unit_from_list, "kg")
    }

    context "when unit_value is zero variant.weight is present" do
      let(:variant) { build_stubbed(:variant, product: product, unit_value: 0, weight: 10.0) }

      it "uses the variant weight" do
        expect(subject.compute(line_item)).to eq 50.0
      end
    end

    context "when unit_value is zero variant.weight is nil" do
      let(:variant) { build_stubbed(:variant, product: product, unit_value: 0, weight: nil) }

      it "uses zero weight" do
        expect(subject.compute(line_item)).to eq 0
      end
    end

    context "when unit_value is nil and variant.weight is present" do
      let(:variant) {
        build_stubbed(:variant, product: product, unit_description: "bunches", unit_value: nil,
                                weight: 10.0)
      }

      it "uses the variant weight" do
        line_item.final_weight_volume = 1

        expect(subject.compute(line_item)).to eq 50.0
      end
    end

    context "when unit_value is nil and variant.weight is nil" do
      let(:variant) {
        build_stubbed(:variant, product: product, unit_description: "bunches", unit_value: nil,
                                weight: nil)
      }

      it "uses zero weight" do
        line_item.final_weight_volume = 1

        expect(subject.compute(line_item)).to eq 0
      end
    end
  end

  it "allows a preferred_unit of 'kg' and 'lb'" do
    subject.calculable = build(:shipping_method)
    subject.set_preference(:per_unit, 5)
    subject.set_preference(:unit_from_list, "kg")
    expect(subject.calculable.errors.count).to eq(0)
    subject.set_preference(:unit_from_list, "lb")
    expect(subject.calculable.errors.count).to eq(0)
  end

  it "does not allow a preferred_unit of anything but 'kg' or 'lb'" do
    subject.calculable = build(:shipping_method)
    subject.set_preference(:per_unit, 5)
    subject.set_preference(:unit_from_list, "kb")
    expect(subject.calculable.errors.count).to eq(1)
  end
end
