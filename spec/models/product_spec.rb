require 'spec_helper'

describe Spree::Product do

  describe "associations" do
    it { should belong_to(:supplier) }
    it { should have_many(:product_distributions) }
  end

  describe "validations" do
    it "is valid when created from factory" do
      create(:product).should be_valid
    end

    it "requires a supplier" do
      product = create(:product)
      product.supplier = nil
      product.should_not be_valid
    end
  end

  context "finders" do
    it "finds the shipping method for a particular distributor" do
      shipping_method = create(:shipping_method)
      distributor = create(:distributor)
      product = create(:product)
      product_distribution = create(:product_distribution, :product => product, :distributor => distributor, :shipping_method => shipping_method)
      product.shipping_method_for_distributor(distributor).should == shipping_method
    end

    it "raises an error if distributor is not found" do
      distributor = create(:distributor)
      product = create(:product)
      expect do
        product.shipping_method_for_distributor(distributor)
      end.to raise_error "This product is not available through that distributor"
    end
  end
end
