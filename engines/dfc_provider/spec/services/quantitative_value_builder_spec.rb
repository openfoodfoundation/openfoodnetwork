# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe QuantitativeValueBuilder do
  subject(:builder) { described_class }
  let(:variant) { build(:variant, product:) }
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
    let(:quantity_unit) { DfcLoader.connector.MEASURES }
    let(:product) { Spree::Product.new }

    it "uses items for anything unknown" do
      quantity = DataFoodConsortium::Connector::QuantitativeValue.new(
        unit: quantity_unit.JAR,
        value: 3,
      )

      builder.apply(quantity, product)

      expect(product.variant_unit).to eq "items"
      expect(product.variant_unit_name).to eq "Jar"
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
      expect(product.variant_unit_name).to eq nil
      expect(product.variant_unit_scale).to eq 1
      expect(product.unit_value).to eq 2
    end

    it "knows metric units with a scale in OFN" do
      quantity = DataFoodConsortium::Connector::QuantitativeValue.new(
        unit: quantity_unit.KILOGRAM,
        value: 4,
      )

      builder.apply(quantity, product)

      expect(product.variant_unit).to eq "weight"
      expect(product.variant_unit_name).to eq nil
      expect(product.variant_unit_scale).to eq 1_000
      expect(product.unit_value).to eq 4_000
    end

    it "knows metric units with a small scale" do
      quantity = DataFoodConsortium::Connector::QuantitativeValue.new(
        unit: quantity_unit.MILLIGRAM,
        value: 5,
      )

      builder.apply(quantity, product)

      expect(product.variant_unit).to eq "weight"
      expect(product.variant_unit_name).to eq nil
      expect(product.variant_unit_scale).to eq 0.001
      expect(product.unit_value).to eq 0.005
    end

    it "interpretes values given as a string" do
      quantity = DataFoodConsortium::Connector::QuantitativeValue.new(
        unit: quantity_unit.KILOGRAM,
        value: "0.4",
      )

      builder.apply(quantity, product)

      expect(product.variant_unit).to eq "weight"
      expect(product.variant_unit_name).to eq nil
      expect(product.variant_unit_scale).to eq 1_000
      expect(product.unit_value).to eq 400
    end

    it "knows imperial units" do
      quantity = DataFoodConsortium::Connector::QuantitativeValue.new(
        unit: quantity_unit.POUNDMASS,
        value: 10,
      )

      builder.apply(quantity, product)

      expect(product.variant_unit).to eq "weight"
      expect(product.variant_unit_name).to eq nil
      expect(product.variant_unit_scale).to eq 453.59237
      expect(product.unit_value).to eq 4_535.9237
    end

    it "knows customary units" do
      quantity = DataFoodConsortium::Connector::QuantitativeValue.new(
        unit: quantity_unit.DOZEN,
        value: 2,
      )

      builder.apply(quantity, product)

      expect(product.variant_unit).to eq "items"
      expect(product.variant_unit_name).to eq "dozen"
      expect(product.variant_unit_scale).to eq 12
      expect(product.unit_value).to eq 24
    end
  end
end
