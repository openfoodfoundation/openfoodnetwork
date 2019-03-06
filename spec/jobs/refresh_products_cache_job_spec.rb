require 'spec_helper'
require 'open_food_network/products_renderer'

describe RefreshProductsCacheJob do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle) }

  context 'when the enterprise and the order cycle exist' do
    before do
      refresh_products_cache_job = instance_double(OpenFoodNetwork::ProductsRenderer, products_json: 'products')
      allow(OpenFoodNetwork::ProductsRenderer).to receive(:new).with(distributor, order_cycle) { refresh_products_cache_job }
    end

    it 'renders products and writes them to cache' do
      run_job RefreshProductsCacheJob.new distributor.id, order_cycle.id
      expect(Rails.cache.read("products-json-#{distributor.id}-#{order_cycle.id}")).to eq 'products'
    end
  end

  context 'when the order cycle does not exist' do
    before do
      allow(OrderCycle)
        .to receive(:find)
        .with(order_cycle.id)
        .and_raise(ActiveRecord::RecordNotFound)
    end

    it 'does not raise' do
      expect {
        run_job RefreshProductsCacheJob.new(distributor.id, order_cycle.id)
      }.not_to raise_error(/ActiveRecord::RecordNotFound/)
    end

    it 'returns true' do
      refresh_products_cache_job = RefreshProductsCacheJob.new(distributor.id, order_cycle.id)
      expect(refresh_products_cache_job.perform).to eq(true)
    end
  end

  describe "fetching products JSON" do
    let(:job) { RefreshProductsCacheJob.new(distributor.id, order_cycle.id) }
    let(:products_renderer) { instance_double(OpenFoodNetwork::ProductsRenderer, products_json: nil) }

    before do
      allow(OpenFoodNetwork::ProductsRenderer).to receive(:new).with(distributor, order_cycle) { products_renderer }
    end

    it "fetches products JSON" do
      job.perform
      expect(OpenFoodNetwork::ProductsRenderer).to have_received(:new).with(distributor, order_cycle) { products_renderer }
    end
  end
end
