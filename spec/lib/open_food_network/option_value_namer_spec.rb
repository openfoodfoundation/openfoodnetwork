require 'spec_helper'

module OpenFoodNetwork
  describe OptionValueNamer do
    describe "generating option value name" do
<<<<<<< HEAD
      let(:v) { Spree::Variant.new }
      let(:subject) { OptionValueNamer.new v }

      it "when description is blank" do
        v.stub(:unit_description) { nil }
=======
      it "when description is blank" do
        v = Spree::Variant.new unit_description: nil
        subject = OptionValueNamer.new v
>>>>>>> Move option value naming logic into separate lib class
        subject.stub(:value_scaled?) { true }
        subject.stub(:option_value_value_unit) { %w(value unit) }
        subject.name.should == "valueunit"
      end

      it "when description is present" do
<<<<<<< HEAD
        v.stub(:unit_description) { 'desc' }
=======
        v = Spree::Variant.new unit_description: 'desc'
        subject = OptionValueNamer.new v
>>>>>>> Move option value naming logic into separate lib class
        subject.stub(:option_value_value_unit) { %w(value unit) }
        subject.stub(:value_scaled?) { true }
        subject.name.should == "valueunit desc"
      end

      it "when value is blank and description is present" do
<<<<<<< HEAD
        v.stub(:unit_description) { 'desc' }
=======
        v = Spree::Variant.new unit_description: 'desc'
        subject = OptionValueNamer.new v
>>>>>>> Move option value naming logic into separate lib class
        subject.stub(:option_value_value_unit) { [nil, nil] }
        subject.stub(:value_scaled?) { true }
        subject.name.should == "desc"
      end

      it "spaces value and unit when value is unscaled" do
<<<<<<< HEAD
        v.stub(:unit_description) { nil }
=======
        v = Spree::Variant.new unit_description: nil
        subject = OptionValueNamer.new v
>>>>>>> Move option value naming logic into separate lib class
        subject.stub(:option_value_value_unit) { %w(value unit) }
        subject.stub(:value_scaled?) { false }
        subject.name.should == "value unit"
      end
    end

    describe "determining if a variant's value is scaled" do
      it "returns true when the product has a scale" do
        p = Spree::Product.new variant_unit_scale: 1000
        v = Spree::Variant.new
        v.stub(:product) { p }
        subject = OptionValueNamer.new v

        subject.value_scaled?.should be_true
      end

      it "returns false otherwise" do
        p = Spree::Product.new
        v = Spree::Variant.new
        v.stub(:product) { p }
        subject = OptionValueNamer.new v

        subject.value_scaled?.should be_false
      end
    end

    describe "generating option value's value and unit" do
      let(:v) { Spree::Variant.new }
      let(:subject) { OptionValueNamer.new v }

      it "generates simple values" do
        p = double(:product, variant_unit: 'weight', variant_unit_scale: 1.0)
        v.stub(:product) { p }
        v.stub(:unit_value) { 100 }
        

        subject.option_value_value_unit.should == [100, 'g']
      end

      it "generates values when unit value is non-integer" do
        p = double(:product, variant_unit: 'weight', variant_unit_scale: 1.0)
        v.stub(:product) { p }
        v.stub(:unit_value) { 123.45 }

        subject.option_value_value_unit.should == [123.45, 'g']
      end

      it "returns a value of 1 when unit value equals the scale" do
        p = double(:product, variant_unit: 'weight', variant_unit_scale: 1000.0)
        v.stub(:product) { p }
        v.stub(:unit_value) { 1000.0 }

        subject.option_value_value_unit.should == [1, 'kg']
      end

      it "generates values for all weight scales" do
        [[1.0, 'g'], [1000.0, 'kg'], [1000000.0, 'T']].each do |scale, unit|
          p = double(:product, variant_unit: 'weight', variant_unit_scale: scale)
          v.stub(:product) { p }
          v.stub(:unit_value) { 100 * scale }
          subject.option_value_value_unit.should == [100, unit]
        end
      end

      it "generates values for all volume scales" do
        [[0.001, 'mL'], [1.0, 'L'], [1000000.0, 'ML']].each do |scale, unit|
          p = double(:product, variant_unit: 'volume', variant_unit_scale: scale)
          v.stub(:product) { p }
          v.stub(:unit_value) { 100 * scale }
          subject.option_value_value_unit.should == [100, unit]
        end
      end

      it "chooses the correct scale when value is very small" do
        p = double(:product, variant_unit: 'volume', variant_unit_scale: 0.001)
        v.stub(:product) { p }
        v.stub(:unit_value) { 0.0001 }
        subject.option_value_value_unit.should == [0.1, 'mL']
      end

      it "generates values for item units" do
        %w(packet box).each do |unit|
          p = double(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: unit)
          v.stub(:product) { p }
          v.stub(:unit_value) { 100 }
          subject.option_value_value_unit.should == [100, unit.pluralize]
        end
      end

      it "generates singular values for item units when value is 1" do
        p = double(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: 'packet')
        v.stub(:product) { p }
        v.stub(:unit_value) { 1 }
        subject.option_value_value_unit.should == [1, 'packet']
      end

      it "returns [nil, nil] when unit value is not set" do
        p = double(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: 'foo')
        v.stub(:product) { p }
        v.stub(:unit_value) { nil }
        subject.option_value_value_unit.should == [nil, nil]
      end
    end
  end
end