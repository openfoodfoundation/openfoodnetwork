require 'spec_helper'

module Spree
  describe ProductsHelper do
    it "displays variant price differences as absolute, not relative values" do
      variant = make_variant_stub(10.00, 10.00)
      helper.variant_price_diff(variant).should == "($10.00)"

      variant = make_variant_stub(10.00, 15.55)
      helper.variant_price_diff(variant).should == "($15.55)"

      variant = make_variant_stub(10.00, 5.55)
      helper.variant_price_diff(variant).should == "($5.55)"
    end

    private
    def make_variant_stub(product_price, variant_price)
      product = double(:product, price: product_price)
      variant = double(:variant, product: product, price: variant_price)
      variant
    end
  end
end
