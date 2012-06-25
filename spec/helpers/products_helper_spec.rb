require 'spec_helper'

module Spree
  describe ProductsHelper do
    subject do
      obj = Object.new
      obj.extend(ProductsHelper)
      obj.extend(ActionView::Helpers::NumberHelper)
    end


    it "displays variant price differences as absolute, not relative values" do
      variant = make_variant_stub(10.00, 10.00)
      subject.variant_price_diff(variant).should be_nil

      variant = make_variant_stub(10.00, 15.55)
      subject.variant_price_diff(variant).should == "($15.55)"

      variant = make_variant_stub(10.00, 5.55)
      subject.variant_price_diff(variant).should == "($5.55)"
    end

    private
    def make_variant_stub(product_price, variant_price)
      product = stub(:product)
      product.stub(:price).and_return(product_price)

      variant = stub(:variant)
      variant.stub(:product).and_return(product)
      variant.stub(:price).and_return(variant_price)

      variant
    end
  end
end
