require 'spec_helper'

describe Spree::OrdersController, type: :controller, performance: true do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], variants: products.map { |p| p.variants.first }) }
  let(:products) { (0..9).map { create(:product) } }
  let(:order) { subject.current_order(true) }
  let(:num_runs) { 2 }

  before do
    order.set_distribution! distributor, order_cycle
    controller.stub(:current_order) { order }

    Spree::Config.currency = 'AUD'
  end

  describe "adding products to cart" do
    it "adds products to cart" do
      puts "1 product, #{num_runs} times..."
      multi_benchmark(3) do
        num_runs.times do
          expect do
            spree_post :populate, variants: {products[0].variants.first.id => 1}
          end.to change(Spree::LineItem, :count).by(1)
          order.empty!
        end
      end

      puts "10 products, #{num_runs} times..."
      variants = Hash[ products.map { |p| [p.variants.first.id, 1] } ]
      multi_benchmark(3) do
        num_runs.times do
          expect do
            spree_post :populate, variants: variants
          end.to change(Spree::LineItem, :count).by(10)
          order.empty!
        end
      end
    end
  end
end
