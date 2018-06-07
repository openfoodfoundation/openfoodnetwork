require 'spec_helper'

describe Spree::OrdersController, type: :controller, performance: true do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], variants: products.map { |p| p.variants.first }) }
  let(:products) { (0...num_products).map { create(:product) } }
  let(:order) { subject.current_order(true) }
  let(:num_products) { 20 }

  before do
    order.set_distribution! distributor, order_cycle
    controller.stub(:current_order) { order }

    Spree::Config.currency = 'AUD'
  end

  describe "adding products to cart" do
    it "adds products to cart" do
      puts "Pre-populating first product"
      spree_post :populate, variants: {products[0].variants.first.id => 1}

      result = Benchmark.measure do
        (1..num_products).each do |num_products|
          puts "Populating #{num_products} products"
          variants = Hash[ products.map { |p| [p.variants.first.id, 1] }.first(num_products) ]
          spree_post :populate, variants: variants
        end
      end

      puts result
    end
  end
end
