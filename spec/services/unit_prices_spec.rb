# frozen_string_literal: true

RSpec.describe UnitPrice do
  before do
    allow(Spree::Config).to receive(:available_units).and_return("g,lb,oz,kg,T,mL,L,kL")
  end

  describe "#unit" do
    context "metric" do
      it "returns kg for weight" do
        variant = Spree::Variant.new(variant_unit_scale: 1.0, variant_unit: "weight")

        expect(UnitPrice.new(variant).unit).to eq("kg")
      end

      it "returns L for volume" do
        variant = Spree::Variant.new(variant_unit_scale: 1.0, variant_unit: "volume")

        expect(UnitPrice.new(variant).unit).to eq("L")
      end
    end

    context "imperial" do
      it "returns lbs" do
        variant = Spree::Variant.new(variant_unit_scale: 453.6, variant_unit: "weight")

        expect(UnitPrice.new(variant).unit).to eq("lb")
      end
    end

    context "items" do
      it "returns items if no unit is specified" do
        variant = Spree::Variant.new(variant_unit_name: nil, variant_unit_scale: nil,
                                     variant_unit: "items")

        expect(UnitPrice.new(variant).unit).to eq("Item")
      end

      it "returns the unit if a unit is specified" do
        variant = Spree::Variant.new(variant_unit_name: "bunch", variant_unit_scale: nil,
                                     variant_unit: "items")

        expect(UnitPrice.new(variant).unit).to eq("bunch")
      end
    end
  end

  describe "#denominator" do
    context "metric" do
      it "returns 0.5 for a 500g variant" do
        variant = Spree::Variant.new(variant_unit_scale: 1.0, unit_value: 500,
                                     variant_unit: "weight")

        expect(UnitPrice.new(variant).denominator).to eq(0.5)
      end

      it "returns 2 for a 2kg variant" do
        variant = Spree::Variant.new(variant_unit_scale: 1000, unit_value: 2000,
                                     variant_unit: "weight")

        expect(UnitPrice.new(variant).denominator).to eq(2)
      end

      it "returns 0.5 for a 500mL variant" do
        variant = Spree::Variant.new(variant_unit_scale: 0.001, unit_value: 0.5,
                                     variant_unit: "volume")

        expect(UnitPrice.new(variant).denominator).to eq(0.5)
      end
    end

    context "imperial" do
      it "returns 2 for a 2 pound variant" do
        variant = Spree::Variant.new(variant_unit_scale: 453.6, unit_value: 2 * 453.6,
                                     variant_unit: "weight")

        expect(UnitPrice.new(variant).denominator).to eq(2)
      end
    end

    context "items" do
      it "returns 1 if no unit is specified" do
        variant = Spree::Variant.new(variant_unit_scale: nil, unit_value: 1, variant_unit: "items")

        expect(UnitPrice.new(variant).denominator).to eq(1)
      end

      it "returns 2 for multi-item units" do
        variant = Spree::Variant.new(variant_unit_scale: nil, unit_value: 2, variant_unit: "items")

        expect(UnitPrice.new(variant).denominator).to eq(2)
      end
    end
  end
end
