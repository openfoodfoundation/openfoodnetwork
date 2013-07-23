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

    local_product  = build_product distributor, true,  nil, false
    remote_product = build_product distributor, false, nil, false

    products, products_local, products_remote = subject.split_products_by_distribution [local_product, remote_product], distributor, nil

    products.should be_nil
    products_local.should == [local_product]
    products_remote.should == [remote_product]
  end

  it "splits products by order cycle when an order cycle is selected" do
    order_cycle = double(:order_cycle)

    local_product  = build_product nil, false, order_cycle, true
    remote_product = build_product nil, false, order_cycle, false

    products, products_local, products_remote = subject.split_products_by_distribution [local_product, remote_product], nil, order_cycle

    products.should be_nil
    products_local.should == [local_product]
    products_remote.should == [remote_product]
  end

  it "splits products by both order cycle and distributor when both are selected" do
    distributor = double(:distributor)
    order_cycle = double(:order_cycle)

    neither_product     = build_product distributor, false, order_cycle, false
    distributor_product = build_product distributor, true,  order_cycle, false
    order_cycle_product = build_product distributor, false, order_cycle, true
    both_product        = build_product distributor, true,  order_cycle, true

    orig_products = [neither_product, distributor_product, order_cycle_product, both_product]

    products, products_local, products_remote = subject.split_products_by_distribution orig_products, distributor, order_cycle

    products.should be_nil
    products_local.should == [both_product]
    products_remote.should == [neither_product, distributor_product, order_cycle_product]
  end



  private

  def build_product(distributor, in_distributor, order_cycle, in_order_cycle)
    product = double(:product)

    if distributor
      product.should_receive(:in_distributor?).any_number_of_times.
        with(distributor).and_return(in_distributor)
    end

    if order_cycle
      product.should_receive(:in_order_cycle?).any_number_of_times.
        with(order_cycle).and_return(in_order_cycle)
    end

    product
  end

end
