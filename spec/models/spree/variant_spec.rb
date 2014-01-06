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
          it "creates the option value and assigns it to the variant" do
            p = create(:simple_product, variant_unit: nil, variant_unit_scale: nil)
            v = create(:variant, product: p, unit_value: nil, unit_description: nil)
            p.update_attributes!(variant_unit: 'weight', variant_unit_scale: 1)
            ot = Spree::OptionType.find_by_name 'unit_weight'

            expect {
              v.update_attributes!(unit_value: 10, unit_description: 'foo')
            }.to change(Spree::OptionValue, :count).by(1)

            ov = Spree::OptionValue.last
            ov.option_type.should == ot
            ov.name.should == '10 g foo'
            ov.presentation.should == '10 g foo'

            v.option_values.should include ov
          end

          it "correctly generates option value name and presentation"
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
