require 'open_food_web/split_products_by_distribution'

describe OpenFoodWeb::SplitProductsByDistribution do
  let(:products_splitter) { Class.new { include OpenFoodWeb::SplitProductsByDistribution } }
  let(:subject) { products_splitter.new }


  it "does nothing when no distributor or order cycle is selected" do
    orig_products = [double(:product)]

    products, products_local, products_remote = subject.split_products_by_distribution orig_products, nil, nil

    products.should == orig_products
    products_local.should be_nil
    products_remote.should be_nil
  end

  it "splits products by distributor when a distributor is selected" do
    distributor = double(:distributor)
    local_product, remote_product = double(:product), double(:product)
    local_product.should_receive(:in_distributor?).any_number_of_times.
      with(distributor).and_return(true)
    remote_product.should_receive(:in_distributor?).any_number_of_times.
      with(distributor).and_return(false)

    products, products_local, products_remote = subject.split_products_by_distribution [local_product, remote_product], distributor, nil

    products.should be_nil
    products_local.should == [local_product]
    products_remote.should == [remote_product]
  end

  it "splits products by order cycle when an order cycle is selected" do
    order_cycle = double(:order_cycle)
    local_product, remote_product = double(:product), double(:product)
    local_product.should_receive(:in_order_cycle?).any_number_of_times.
      with(order_cycle).and_return(true)
    remote_product.should_receive(:in_order_cycle?).any_number_of_times.
      with(order_cycle).and_return(false)

    products, products_local, products_remote = subject.split_products_by_distribution [local_product, remote_product], nil, order_cycle

    products.should be_nil
    products_local.should == [local_product]
    products_remote.should == [remote_product]
  end

  it "splits products by both order cycle and distributor when both are selected" do
    distributor = double(:distributor)
    order_cycle = double(:order_cycle)

    neither_product, distributor_product, order_cycle_product, both_product =
      double(:product), double(:product), double(:product), double(:product)

    neither_product.should_receive(:in_distributor?).any_number_of_times.
      with(distributor).and_return(false)
    neither_product.should_receive(:in_order_cycle?).any_number_of_times.
      with(order_cycle).and_return(false)

    distributor_product.should_receive(:in_distributor?).any_number_of_times.
      with(distributor).and_return(true)
    distributor_product.should_receive(:in_order_cycle?).any_number_of_times.
      with(order_cycle).and_return(false)

    order_cycle_product.should_receive(:in_distributor?).any_number_of_times.
      with(distributor).and_return(false)
    order_cycle_product.should_receive(:in_order_cycle?).any_number_of_times.
      with(order_cycle).and_return(true)

    both_product.should_receive(:in_distributor?).any_number_of_times.
      with(distributor).and_return(true)
    both_product.should_receive(:in_order_cycle?).any_number_of_times.
      with(order_cycle).and_return(true)

    orig_products = [neither_product, distributor_product, order_cycle_product, both_product]

    products, products_local, products_remote = subject.split_products_by_distribution orig_products, distributor, order_cycle

    products.should be_nil
    products_local.should == [both_product]
    products_remote.should == [neither_product, distributor_product, order_cycle_product]
  end
end
