require 'spec_helper'

module Spree
  describe OptionType do
    describe "products cache" do
      let!(:product) { create(:simple_product, option_types: [option_type]) }
      let(:variant) { product.variants.first }
      let(:option_type) { create(:option_type) }
      let(:option_value) { create(:option_value, option_type: option_type) }

      before do
        option_type.reload
        variant.option_values << option_value
      end

      it "refreshes the products cache on change, via product" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
        option_type.name = 'foo'
        option_type.save!
      end

      it "refreshes the products cache on destruction, via option value destruction" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:variant_changed).with(variant)
        option_type.destroy
      end
    end
  end
end
