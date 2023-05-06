# frozen_string_literal: true

require 'spec_helper'

module VariantUnits
  describe OptionValueNamer do
    describe "generating option value name" do
      let(:v) { Spree::Variant.new }
      let(:p) { Spree::Product.new }
      let(:subject) { OptionValueNamer.new(v) }

      it "when description is blank" do
        allow(v).to receive(:unit_description) { nil }
        allow(subject).to receive(:value_scaled?) { true }
        allow(subject).to receive(:option_value_value_unit) { %w(value unit) }
        expect(subject.name).to eq("valueunit")
      end

      it "when description is present" do
        allow(v).to receive(:unit_description) { 'desc' }
        allow(subject).to receive(:option_value_value_unit) { %w(value unit) }
        allow(subject).to receive(:value_scaled?) { true }
        expect(subject.name).to eq("valueunit desc")
      end

      it "when value is blank and description is present" do
        allow(v).to receive(:unit_description) { 'desc' }
        allow(subject).to receive(:option_value_value_unit) { [nil, nil] }
        allow(subject).to receive(:value_scaled?) { true }
        expect(subject.name).to eq("desc")
      end

      it "spaces value and unit when value is unscaled" do
        allow(v).to receive(:unit_description) { nil }
        allow(subject).to receive(:option_value_value_unit) { %w(value unit) }
        allow(subject).to receive(:value_scaled?) { false }
        expect(subject.name).to eq("value unit")
      end
    end

    describe "determining if a variant's value is scaled" do
      it "returns true when the product has a scale" do
        p = Spree::Product.new variant_unit_scale: 1000
        v = Spree::Variant.new
        allow(v).to receive(:product) { p }
        subject = OptionValueNamer.new v

        expect(subject.send(:value_scaled?)).to be true
      end

      it "returns false otherwise" do
        p = Spree::Product.new
        v = Spree::Variant.new
        allow(v).to receive(:product) { p }
        subject = OptionValueNamer.new v

        expect(subject.send(:value_scaled?)).to be false
      end
    end

    describe "generating option value's value and unit" do
      let(:v) { Spree::Variant.new }
      let(:subject) { OptionValueNamer.new v }

      it "generates simple values" do
        p = double(:product, variant_unit: 'weight', variant_unit_scale: 1.0)
        allow(v).to receive(:product) { p }
        allow(p).to receive(:persisted?) { true }
        allow(v).to receive(:unit_value) { 100 }

        expect(subject.send(:option_value_value_unit)).to eq [100, 'g']
      end

      it "generates values when unit value is non-integer" do
        p = double(:product, variant_unit: 'weight', variant_unit_scale: 1.0)
        allow(v).to receive(:product) { p }
        allow(p).to receive(:persisted?) { true }
        allow(v).to receive(:unit_value) { 123.45 }

        expect(subject.send(:option_value_value_unit)).to eq [123.45, 'g']
      end

      it "returns a value of 1 when unit value equals the scale" do
        p = double(:product, variant_unit: 'weight', variant_unit_scale: 1000.0)
        allow(v).to receive(:product) { p }
        allow(p).to receive(:persisted?) { true }
        allow(v).to receive(:unit_value) { 1000.0 }

        expect(subject.send(:option_value_value_unit)).to eq [1, 'kg']
      end

      it "returns only values that are in the same measurement systems" do
        p = double(:product, variant_unit: 'weight', variant_unit_scale: 1.0)
        allow(v).to receive(:product) { p }
        allow(p).to receive(:persisted?) { true }
        allow(v).to receive(:unit_value) { 500 }
        # 500g would convert to > 1 pound, but we don't want the namer to use
        # pounds since it's in a different measurement system.
        expect(subject.send(:option_value_value_unit)).to eq [500, 'g']
      end

      it "generates values for all weight scales" do
        [[1.0, 'g'], [28.35, 'oz'], [453.6, 'lb'], [1000.0, 'kg'],
         [1_000_000.0, 'T']].each do |scale, unit|
          p = double(:product, variant_unit: 'weight', variant_unit_scale: scale)
          allow(v).to receive(:product) { p }
          allow(p).to receive(:persisted?) { true }
          allow(v).to receive(:unit_value) { 10.0 * scale }
          expect(subject.send(:option_value_value_unit)).to eq [10, unit]
        end
      end

      it "generates values for all volume scales" do
        [[0.001, 'mL'], [1.0, 'L'], [1000.0, 'kL']].each do |scale, unit|
          p = double(:product, variant_unit: 'volume', variant_unit_scale: scale)
          allow(v).to receive(:product) { p }
          allow(p).to receive(:persisted?) { true }
          allow(v).to receive(:unit_value) { 100 * scale }
          expect(subject.send(:option_value_value_unit)).to eq [100, unit]
        end
      end

      it "chooses the correct scale when value is very small" do
        p = double(:product, variant_unit: 'volume', variant_unit_scale: 0.001)
        allow(v).to receive(:product) { p }
        allow(p).to receive(:persisted?) { true }
        allow(v).to receive(:unit_value) { 0.0001 }
        expect(subject.send(:option_value_value_unit)).to eq [0.1, 'mL']
      end

      it "generates values for item units" do
        %w(packet box).each do |unit|
          p = double(:product, variant_unit: 'items', variant_unit_scale: nil,
                               variant_unit_name: unit)
          allow(v).to receive(:product) { p }
          allow(p).to receive(:persisted?) { true }
          allow(v).to receive(:unit_value) { 100 }
          expect(subject.send(:option_value_value_unit)).to eq [100, unit.pluralize]
        end
      end

      it "generates singular values for item units when value is 1" do
        p = double(:product, variant_unit: 'items', variant_unit_scale: nil,
                             variant_unit_name: 'packet')
        allow(v).to receive(:product) { p }
        allow(p).to receive(:persisted?) { true }
        allow(v).to receive(:unit_value) { 1 }
        expect(subject.send(:option_value_value_unit)).to eq [1, 'packet']
      end

      it "returns [nil, nil] when unit value is not set" do
        p = double(:product, variant_unit: 'items', variant_unit_scale: nil,
                             variant_unit_name: 'foo')
        allow(v).to receive(:product) { p }
        allow(v).to receive(:unit_value) { nil }
        expect(subject.send(:option_value_value_unit)).to eq [nil, nil]
      end

      it "truncates value to 2 decimals maximum" do
        oz_scale = 28.35
        p = double(:product, variant_unit: 'weight', variant_unit_scale: oz_scale)
        allow(v).to receive(:product) { p }
        allow(p).to receive(:persisted?) { true }
        # The unit_value is stored rounded to 2 decimals
        allow(v).to receive(:unit_value) { (12.5 * oz_scale).round(2) }
        expect(subject.send(:option_value_value_unit)).to eq [BigDecimal(12.5, 6), 'oz']
      end
    end
  end
end
