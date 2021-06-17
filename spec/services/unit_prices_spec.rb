# frozen_string_literal: true

require 'spec_helper'

describe UnitPrice do
  subject { UnitPrice.new(variant) }
  let(:variant) { Spree::Variant.new }
  let(:product) { instance_double(Spree::Product) }

  before do
    allow(variant).to receive(:product) { product }
  end

  describe "#unit" do
    context "metric" do
      before do
        allow(product).to receive(:variant_unit_scale) { 1.0 }
      end

      it "returns kg for weight" do
        allow(product).to receive(:variant_unit) { "weight" }
        expect(subject.unit).to eq("kg")
      end

      it "returns L for volume" do
        allow(product).to receive(:variant_unit) { "volume" }
        expect(subject.unit).to eq("L")
      end
    end

    context "imperial" do
      it "returns lbs" do
        allow(product).to receive(:variant_unit_scale) { 453.6 }
        allow(product).to receive(:variant_unit) { "weight" }
        expect(subject.unit).to eq("lb")
      end
    end

    context "items" do
      it "returns items if no unit is specified" do
        allow(product).to receive(:variant_unit_name) { nil }
        allow(product).to receive(:variant_unit_scale) { nil }
        allow(product).to receive(:variant_unit) { "items" }
        expect(subject.unit).to eq("Item")
      end

      it "returns the unit if a unit is specified" do
        allow(product).to receive(:variant_unit_name) { "bunch" }
        allow(product).to receive(:variant_unit_scale) { nil }
        allow(product).to receive(:variant_unit) { "items" }
        expect(subject.unit).to eq("bunch")
      end
    end
  end

  describe "#denominator" do
    context "metric" do
      it "returns 0.5 for a 500g variant" do
        allow(product).to receive(:variant_unit_scale) { 1.0 }
        allow(product).to receive(:variant_unit) { "weight" }
        variant.unit_value = 500
        expect(subject.denominator).to eq(0.5)
      end

      it "returns 2 for a 2kg variant" do
        allow(product).to receive(:variant_unit_scale) { 1000 }
        allow(product).to receive(:variant_unit) { "weight" }
        variant.unit_value = 2000
        expect(subject.denominator).to eq(2)
      end

      it "returns 0.5 for a 500mL variant" do
        allow(product).to receive(:variant_unit_scale) { 0.001 }
        allow(product).to receive(:variant_unit) { "volume" }
        variant.unit_value = 0.5
        expect(subject.denominator).to eq(0.5)
      end
    end

    context "imperial" do
      it "returns 2 for a 2 pound variant" do
        allow(product).to receive(:variant_unit_scale) { 453.6 }
        allow(product).to receive(:variant_unit) { "weight" }
        variant.unit_value = 2 * 453.6
        expect(subject.denominator).to eq(2)
      end
    end

    context "items" do
      it "returns 1 if no unit is specified" do
        allow(product).to receive(:variant_unit_scale) { nil }
        allow(product).to receive(:variant_unit) { "items" }
        variant.unit_value = 1
        expect(subject.denominator).to eq(1)
      end

      it "returns 2 for multi-item units" do
        allow(product).to receive(:variant_unit_scale) { nil }
        allow(product).to receive(:variant_unit) { "items" }
        variant.unit_value = 2
        expect(subject.denominator).to eq(2)
      end
    end
  end
end
