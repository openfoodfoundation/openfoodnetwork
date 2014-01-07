require 'spec_helper'

module Spree
  describe Variant do
    context "when the product has variants" do
      let!(:product) { create(:simple_product) }
      let!(:variant) { create(:variant, product: product) }

      %w(weight volume).each do |unit|
        context "when the product's unit is #{unit}" do
          before do
            product.update_attribute :variant_unit, unit
            product.reload
          end

          it "is valid when unit value is set and unit description is not" do
            variant.unit_value = 1
            variant.unit_description = nil
            variant.should be_valid
          end

          it "is invalid when unit value is not set" do
            variant.unit_value = nil
            variant.should_not be_valid
          end

          it "has a valid master variant" do
            product.master.should be_valid
          end
        end
      end

      context "when the product's unit is items" do
        before do
          product.update_attribute :variant_unit, 'items'
          product.reload
        end

        it "is valid with only unit value set" do
          variant.unit_value = 1
          variant.unit_description = nil
          variant.should be_valid
        end

        it "is valid with only unit description set" do
          variant.unit_value = nil
          variant.unit_description = 'Medium'
          variant.should be_valid
        end

        it "is invalid when neither unit value nor unit description are set" do
          variant.unit_value = nil
          variant.unit_description = nil
          variant.should_not be_valid
        end

        it "has a valid master variant" do
          product.master.should be_valid
        end
      end
    end

    context "when the product does not have variants" do
      let(:product) { create(:simple_product, variant_unit: nil) }
      let(:variant) { product.master }

      it "does not require unit value or unit description when the product's unit is empty" do
        variant.unit_value = nil
        variant.unit_description = nil
        variant.should be_valid
      end
    end

    describe "unit value/description" do
      context "when the variant initially has no value" do
        context "when the required option value does not exist" do
          let!(:p) { create(:simple_product, variant_unit: nil, variant_unit_scale: nil) }
          let!(:v) { create(:variant, product: p, unit_value: nil, unit_description: nil) }

          before do
            p.update_attributes!(variant_unit: 'weight', variant_unit_scale: 1)
            @ot = Spree::OptionType.find_by_name 'unit_weight'
          end

          it "creates the option value and assigns it to the variant" do
            expect {
              v.update_attributes!(unit_value: 10, unit_description: 'foo')
            }.to change(Spree::OptionValue, :count).by(1)

            ov = Spree::OptionValue.last
            ov.option_type.should == @ot
            ov.name.should == '10 g foo'
            ov.presentation.should == '10 g foo'

            v.option_values.should include ov
          end
        end

        context "when the required option value already exists" do
          it "looks up the option value and assigns it to the variant"
        end

        context "when the variant already has a value set (and all required option values exist)" do
          it "removes the old option value and assigns the new one"
          it "leaves option value unassigned if none is provided"
          it "does not remove and re-add the option value if it is not changed"
        end
      end

      describe "generating option value name" do
        it "when description is blank" do
          v = Spree::Variant.new unit_description: nil
          v.stub(:option_value_value_unit) { %w(value unit) }
          v.send(:option_value_name).should == "value unit"
        end

        it "when description is present" do
          v = Spree::Variant.new unit_description: 'desc'
          v.stub(:option_value_value_unit) { %w(value unit) }
          v.send(:option_value_name).should == "value unit desc"
        end

        it "when value is blank and description is present" do
          v = Spree::Variant.new unit_description: 'desc'
          v.stub(:option_value_value_unit) { [nil, nil] }
          v.send(:option_value_name).should == "desc"
        end
      end

      describe "generating option value's value and unit" do
        let(:v) { Spree::Variant.new }

        it "generates simple values" do
          p = double(:product, variant_unit: 'weight', variant_unit_scale: 1.0)
          v.stub(:product) { p }
          v.stub(:unit_value) { 100 }

          v.send(:option_value_value_unit).should == [100, 'g']
        end

        it "generates values when unit value is non-integer" do
          p = double(:product, variant_unit: 'weight', variant_unit_scale: 1.0)
          v.stub(:product) { p }
          v.stub(:unit_value) { 123.45 }

          v.send(:option_value_value_unit).should == [123.45, 'g']
        end

        it "generates values for all weight scales" do
          [[1.0, 'g'], [1000.0, 'kg'], [1000000.0, 'T']].each do |scale, unit|
            p = double(:product, variant_unit: 'weight', variant_unit_scale: scale)
            v.stub(:product) { p }
            v.stub(:unit_value) { 100 * scale }
            v.send(:option_value_value_unit).should == [100, unit]
          end
        end

        it "generates values for all volume scales" do
          [[0.001, 'mL'], [1.0, 'L'], [1000000.0, 'ML']].each do |scale, unit|
            p = double(:product, variant_unit: 'volume', variant_unit_scale: scale)
            v.stub(:product) { p }
            v.stub(:unit_value) { 100 * scale }
            v.send(:option_value_value_unit).should == [100, unit]
          end
        end

        it "generates values for item units" do
          %w(packet box).each do |unit|
            p = double(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: unit)
            v.stub(:product) { p }
            v.stub(:unit_value) { 100 }
            v.send(:option_value_value_unit).should == [100, unit.pluralize]
          end
        end

        it "generates singular values for item units when value is 1" do
          p = double(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: 'packet')
          v.stub(:product) { p }
          v.stub(:unit_value) { 1 }
          v.send(:option_value_value_unit).should == [1, 'packet']
        end

        it "returns [nil, nil] when unit value is not set" do
          p = double(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: 'foo')
          v.stub(:product) { p }
          v.stub(:unit_value) { nil }
          v.send(:option_value_value_unit).should == [nil, nil]
        end
      end
    end

    describe "deleting unit option values" do
      before do
        p = create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1)
        ot = Spree::OptionType.find_by_name 'unit_weight'
        @v = create(:variant, product: p)
      end

      it "removes option value associations for unit option types" do
        expect {
          @v.delete_unit_option_values
        }.to change(@v.option_values, :count).by(-1)
      end

      it "does not delete option values" do
        expect {
          @v.delete_unit_option_values
        }.to change(Spree::OptionValue, :count).by(0)
      end
    end
  end
end
