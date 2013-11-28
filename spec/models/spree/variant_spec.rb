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
  end
end
