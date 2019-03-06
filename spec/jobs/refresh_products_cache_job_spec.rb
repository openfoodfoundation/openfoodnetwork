require 'spec_helper'
require 'open_food_network/products_renderer'

describe RefreshProductsCacheJob do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle) }

  context 'when the enterprise and the order cycle exist' do
    it "renders products and writes them to cache" do
      RefreshProductsCacheJob.any_instance.stub(:products_json) { 'products' }

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
    let(:job) { RefreshProductsCacheJob.new distributor.id, order_cycle.id }
    let(:pr) { double(:products_renderer, products_json: nil) }

    it "fetches products JSON" do
      expect(OpenFoodNetwork::ProductsRenderer).to receive(:new).with(distributor, order_cycle) { pr }
      job.send(:products_json)
    end
  end
end
