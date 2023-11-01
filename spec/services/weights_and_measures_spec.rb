# frozen_string_literal: true

require 'spec_helper'

describe WeightsAndMeasures do
  subject { WeightsAndMeasures.new(variant) }
  let(:variant) { Spree::Variant.new }
  let(:product) { instance_double(Spree::Product) }

  before do
    allow(variant).to receive(:product) { product }
  end

  describe "#system" do
    context "weight" do
      before do
        allow(product).to receive(:variant_unit) { "weight" }
      end

      it "when scale is for a metric unit" do
        allow(product).to receive(:variant_unit_scale) { 1.0 }
        expect(subject.system).to eq("metric")
      end

      it "when scale is for an imperial unit" do
        allow(product).to receive(:variant_unit_scale) { 28.35 }
        expect(subject.system).to eq("imperial")
      end
    end

    context "volume" do
      it "when scale is for a metric unit" do
        allow(product).to receive(:variant_unit) { "volume" }
        allow(product).to receive(:variant_unit_scale) { 1.0 }
        expect(subject.system).to eq("metric")
      end
    end

    context "items" do
      it "when variant unit is items" do
        allow(product).to receive(:variant_unit) { "items" }
        allow(product).to receive(:variant_unit_scale) { nil }
        expect(subject.system).to eq("custom")
      end

      it "when variant unit is items, even if the scale is present" do
        allow(product).to receive(:variant_unit) { "items" }
        allow(product).to receive(:variant_unit_scale) { 1.0 }
        expect(subject.system).to eq("custom")
      end
    end
  end

  describe "#scale_for_unit_value" do
    context "weight" do
      before do
        allow(product).to receive(:variant_unit) { "weight" }
      end

      context "metric" do
        it "for a unit value that should display in grams" do
          allow(product).to receive(:variant_unit_scale) { 1.0 }
          allow(variant).to receive(:unit_value) { 500 }
          expect(subject.scale_for_unit_value).to eq([1.0, "g"])
        end

        it "for a unit value that should display in kg" do
          allow(product).to receive(:variant_unit_scale) { 1.0 }
          allow(variant).to receive(:unit_value) { 1500 }
          expect(subject.scale_for_unit_value).to eq([1000.0, "kg"])
        end
      end
    end

    context "volume" do
      it "for a unit value that should display in L" do
        allow(product).to receive(:variant_unit) { "volume" }
        allow(product).to receive(:variant_unit_scale) { 1.0 }
        allow(variant).to receive(:unit_value) { 1500 }
        expect(subject.scale_for_unit_value).to eq([1000, "kL"])
      end
    end

    context "items" do
      it "when scale is for items" do
        allow(product).to receive(:variant_unit) { "items" }
        allow(product).to receive(:variant_unit_scale) { nil }
        allow(variant).to receive(:unit_value) { 4 }
        expect(subject.scale_for_unit_value).to eq([nil, nil])
      end
    end
  end
end
