require 'spec_helper'

module Spree
  describe OptionType do
    describe "products cache" do
      let!(:product) { create(:simple_product, option_types: [option_type]) }
      let(:option_type) { create(:option_type) }

      before { option_type.reload }

      it "refreshes the products cache on change, via product" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
        option_type.name = 'foo'
        option_type.save!
      end

      # When a OptionType is destroyed, the destruction of the OptionValues refreshes the cache
    end
  end
end
