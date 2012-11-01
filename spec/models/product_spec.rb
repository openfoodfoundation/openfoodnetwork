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

  describe "scopes" do
    describe "in_supplier_or_distributor" do
      it "finds supplied products" do
        s0 = create(:supplier_enterprise)
        s1 = create(:supplier_enterprise)
        p0 = create(:product, :supplier => s0)
        p1 = create(:product, :supplier => s1)

        Spree::Product.in_supplier_or_distributor(s1).should == [p1]
      end

      it "finds distributed products" do
        d0 = create(:distributor_enterprise)
        d1 = create(:distributor_enterprise)
        p0 = create(:product, :distributors => [d0])
        p1 = create(:product, :distributors => [d1])

        Spree::Product.in_supplier_or_distributor(d1).should == [p1]
      end

      it "finds products supplied and distributed by the same enterprise" do
        s = create(:supplier_enterprise)
        d = create(:distributor_enterprise)
        p = create(:product, :supplier => s, :distributors => [d])

        Spree::Product.in_supplier_or_distributor(s).should == [p]
        Spree::Product.in_supplier_or_distributor(d).should == [p]
      end
    end
  end

  describe "finders" do
    it "finds the shipping method for a particular distributor" do
      shipping_method = create(:shipping_method)
      distributor = create(:distributor_enterprise)
      product = create(:product)
      product_distribution = create(:product_distribution, :product => product, :distributor => distributor, :shipping_method => shipping_method)
      product.shipping_method_for_distributor(distributor).should == shipping_method
    end

    it "raises an error if distributor is not found" do
      distributor = create(:distributor_enterprise)
      product = create(:product)
      expect do
        product.shipping_method_for_distributor(distributor)
      end.to raise_error "This product is not available through that distributor"
    end
  end
end
