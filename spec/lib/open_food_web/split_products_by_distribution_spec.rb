require 'spec_helper'

describe OpenFoodWeb::SplitProductsByDistribution do
  let(:products_splitter) { Class.new { include OpenFoodWeb::SplitProductsByDistribution } }
  let(:subject) { products_splitter.new }


  it "does nothing when no distributor or order cycle is selected" do
    orig_products = (1..3).map { |i| build(:product) }

    products, products_local, products_remote = subject.split_products_by_distribution orig_products, nil, nil

    products.should == orig_products
    products_local.should be_nil
    products_remote.should be_nil
  end

  it "splits products by product distribution when a distributor is selected" do
    d1 = build(:distributor_enterprise)
    d2 = build(:distributor_enterprise)
    orig_products = [build(:product, :distributors => [d1]),
                     build(:product, :distributors => [d2])]

    products, products_local, products_remote = subject.split_products_by_distribution orig_products, d1, nil

    products.should be_nil
    products_local.should == [orig_products[0]]
    products_remote.should == [orig_products[1]]
  end

  it "splits products by order cycle distribution when a distributor is selected"
  it "splits products by order cycle when an order cycle is selected"
  it "splits products by both order cycle and distributor when both are selected"
end
