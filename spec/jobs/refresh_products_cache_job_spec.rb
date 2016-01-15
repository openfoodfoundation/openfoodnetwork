require 'spec_helper'
require 'open_food_network/products_renderer'

describe RefreshProductsCacheJob do
  let(:distributor_id) { 123 }
  let(:order_cycle_id) { 456 }

  it "renders products and writes them to cache" do
    OpenFoodNetwork::ProductsRenderer.any_instance.stub(:products_json) { 'products' }

    run_job RefreshProductsCacheJob.new distributor_id, order_cycle_id

    expect(Rails.cache.read("products-json-123-456")).to eq 'products'
  end
end
