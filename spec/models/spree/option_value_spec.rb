require 'spec_helper'

module Spree
  describe OptionValue do
    describe "products cache" do
      let(:variant) { create(:variant) }
      let(:option_value) { create(:option_value) }

      before do
        variant.option_values << option_value
        option_value.reload
      end

      it "refreshes the products cache on change, via variant" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:variant_changed).with(variant)
        option_value.name = 'foo'
        option_value.save!
      end

      it "refreshes the products cache on destruction, via variant" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:variant_changed).with(variant)
        option_value.destroy
      end
    end
  end
end
