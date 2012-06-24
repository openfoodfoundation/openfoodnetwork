require 'spec_helper'

describe OpenFoodWeb::SplitProductsByDistributor do
  let(:products_splitter) { Class.new { include OpenFoodWeb::SplitProductsByDistributor } }
  let(:subject) { products_splitter.new }


  it "does nothing when no distributor is selected" do
    orig_products = (1..3).map { |i| build(:product) }

    products, products_local, products_remote = subject.split_products_by_distributor orig_products, nil

    products.should == orig_products
    products_local.should be_nil
    products_remote.should be_nil
  end

  it "splits products when a distributor is selected" do
    d1 = build(:distributor)
    d2 = build(:distributor)
    orig_products = [build(:product, :distributors => [d1]),
                     build(:product, :distributors => [d2])]

    products, products_local, products_remote = subject.split_products_by_distributor orig_products, d1

    products.should be_nil
    products_local.should == [orig_products[0]]
    products_remote.should == [orig_products[1]]
  end
end
