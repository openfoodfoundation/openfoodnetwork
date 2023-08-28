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

  describe ".apply" do
    let(:quantity_unit) { DfcLoader.connector.MEASURES.UNIT.QUANTITYUNIT }
    let(:product) { Spree::Product.new }

    it "uses items for anything unknown" do
      quantity = DataFoodConsortium::Connector::QuantitativeValue.new(
        unit: quantity_unit.JAR,
        value: 3,
      )

      builder.apply(quantity, product)

      expect(product.variant_unit).to eq "items"
      expect(product.variant_unit_name).to eq "items"
      expect(product.variant_unit_scale).to eq 1
      expect(product.unit_value).to eq 3
    end

    it "knows metric units" do
      quantity = DataFoodConsortium::Connector::QuantitativeValue.new(
        unit: quantity_unit.LITRE,
        value: 2,
      )

      builder.apply(quantity, product)

      expect(product.variant_unit).to eq "volume"
      expect(product.variant_unit_name).to eq "liter"
      expect(product.variant_unit_scale).to eq 1
      expect(product.unit_value).to eq 2
    end
  end
end
