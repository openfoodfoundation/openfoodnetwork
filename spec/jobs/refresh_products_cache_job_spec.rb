require 'spec_helper'
require 'open_food_network/products_renderer'

describe RefreshProductsCacheJob do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle) }

  it "renders products and writes them to cache" do
    RefreshProductsCacheJob.any_instance.stub(:products_json) { 'products' }

    run_job RefreshProductsCacheJob.new distributor.id, order_cycle.id

    expect(Rails.cache.read("products-json-#{distributor.id}-#{order_cycle.id}")).to eq 'products'
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
