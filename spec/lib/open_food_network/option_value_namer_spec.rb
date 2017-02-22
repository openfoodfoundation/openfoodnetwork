require 'spec_helper'

module OpenFoodNetwork
  describe OptionValueNamer do
    describe "generating option value name" do
      let(:v) { Spree::Variant.new }
      let(:subject) { OptionValueNamer.new }

      it "when description is blank" do
        v.stub(:unit_description) { nil }
        subject.stub(:value_scaled?) { true }
        subject.stub(:option_value_value_unit) { %w(value unit) }
        subject.name(v).should == "valueunit"
      end

      it "when description is present" do
        v.stub(:unit_description) { 'desc' }
        subject.stub(:option_value_value_unit) { %w(value unit) }
        subject.stub(:value_scaled?) { true }
        subject.name(v).should == "valueunit desc"
      end

      it "when value is blank and description is present" do
        v.stub(:unit_description) { 'desc' }
        subject.stub(:option_value_value_unit) { [nil, nil] }
        subject.stub(:value_scaled?) { true }
        subject.name(v).should == "desc"
      end

      it "spaces value and unit when value is unscaled" do
        v.stub(:unit_description) { nil }
        subject.stub(:option_value_value_unit) { %w(value unit) }
        subject.stub(:value_scaled?) { false }
        subject.name(v).should == "value unit"
      end
    end

    describe "determining if a variant's value is scaled" do
      it "returns true when the product has a scale" do
        p = Spree::Product.new variant_unit_scale: 1000
        v = Spree::Variant.new
        v.stub(:product) { p }
        subject = OptionValueNamer.new v

        expect(subject.send(:value_scaled?)).to be true
      end

      it "returns false otherwise" do
        p = Spree::Product.new
        v = Spree::Variant.new
        v.stub(:product) { p }
        subject = OptionValueNamer.new v

        expect(subject.send(:value_scaled?)).to be false
      end
    end

    describe "generating option value's value and unit" do
      let(:v) { Spree::Variant.new }
      let(:subject) { OptionValueNamer.new v }

      it "generates simple values" do
        p = double(:product, variant_unit: 'weight', variant_unit_scale: 1.0)
        v.stub(:product) { p }
        v.stub(:unit_value) { 100 }


        expect(subject.send(:option_value_value_unit)).to eq [100, 'g']
      end

      it "generates values when unit value is non-integer" do
        p = double(:product, variant_unit: 'weight', variant_unit_scale: 1.0)
        v.stub(:product) { p }
        v.stub(:unit_value) { 123.45 }

        expect(subject.send(:option_value_value_unit)).to eq [123.45, 'g']
      end

      it "returns a value of 1 when unit value equals the scale" do
        p = double(:product, variant_unit: 'weight', variant_unit_scale: 1000.0)
        v.stub(:product) { p }
        v.stub(:unit_value) { 1000.0 }

        expect(subject.send(:option_value_value_unit)).to eq [1, 'kg']
      end

      it "generates values for all weight scales" do
        [[1.0, 'g'], [1000.0, 'kg'], [1000000.0, 'T']].each do |scale, unit|
          p = double(:product, variant_unit: 'weight', variant_unit_scale: scale)
          v.stub(:product) { p }
          v.stub(:unit_value) { 100 * scale }
          expect(subject.send(:option_value_value_unit)).to eq [100, unit]
        end
      end

      it "generates values for all volume scales" do
        [[0.001, 'mL'], [1.0, 'L'], [1000.0, 'kL']].each do |scale, unit|
          p = double(:product, variant_unit: 'volume', variant_unit_scale: scale)
          v.stub(:product) { p }
          v.stub(:unit_value) { 100 * scale }
          expect(subject.send(:option_value_value_unit)).to eq [100, unit]
        end
      end

      it "chooses the correct scale when value is very small" do
        p = double(:product, variant_unit: 'volume', variant_unit_scale: 0.001)
        v.stub(:product) { p }
        v.stub(:unit_value) { 0.0001 }
        expect(subject.send(:option_value_value_unit)).to eq [0.1, 'mL']
      end

      it "generates values for item units" do
        %w(packet box).each do |unit|
          p = double(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: unit)
          v.stub(:product) { p }
          v.stub(:unit_value) { 100 }
          expect(subject.send(:option_value_value_unit)).to eq [100, unit.pluralize]
        end
      end

      it "generates singular values for item units when value is 1" do
        p = double(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: 'packet')
        v.stub(:product) { p }
        v.stub(:unit_value) { 1 }
        expect(subject.send(:option_value_value_unit)).to eq [1, 'packet']
      end

      it "returns [nil, nil] when unit value is not set" do
        p = double(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: 'foo')
        v.stub(:product) { p }
        v.stub(:unit_value) { nil }
        expect(subject.send(:option_value_value_unit)).to eq [nil, nil]
      end
    end
  end
end
