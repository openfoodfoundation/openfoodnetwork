# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe QuantitativeValueBuilder do
  subject(:builder) { described_class }
  let(:variant) { build(:variant, product: product) }
  let(:product) { build(:product, name: "Apple") }

  describe ".quantity" do
    it "recognises items" do
      product.variant_unit = "item"
      variant.unit_value = 1
      quantity = builder.quantity(variant)

      expect(quantity.value).to eq 1.0
      expect(quantity.unit.semanticId).to eq "dfc-m:Piece"
    end

    it "recognises volume" do
      product.variant_unit = "volume"
      variant.unit_value = 2
      quantity = builder.quantity(variant)

      expect(quantity.value).to eq 2.0
      expect(quantity.unit.semanticId).to eq "dfc-m:Litre"
    end

    it "recognises weight" do
      product.variant_unit = "weight"
      variant.unit_value = 1000 # 1kg
      quantity = builder.quantity(variant)

      expect(quantity.value).to eq 1000.0
      expect(quantity.unit.semanticId).to eq "dfc-m:Gram"
    end

    it "falls back to items" do
      product.variant_unit = nil
      quantity = builder.quantity(variant)

      expect(quantity.value).to eq 1.0
      expect(quantity.unit.semanticId).to eq "dfc-m:Piece"
    end
  end
end
