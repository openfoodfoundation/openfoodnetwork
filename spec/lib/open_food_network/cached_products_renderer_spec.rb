require 'spec_helper'
require 'open_food_network/cached_products_renderer'
require 'open_food_network/products_renderer'

module OpenFoodNetwork
  describe CachedProductsRenderer do
    let(:distributor) { double(:distributor, id: 123) }
    let(:order_cycle) { double(:order_cycle, id: 456) }
    let(:cpr) { CachedProductsRenderer.new(distributor, order_cycle) }

    describe "when the products JSON is already cached" do
      before do
        Rails.cache.write "products-json-#{distributor.id}-#{order_cycle.id}", 'products'
      end

      it "returns the cached JSON" do
        expect(cpr.products_json).to eq 'products'
      end

      it "raises an exception when there are no products" do
        Rails.cache.write "products-json-#{distributor.id}-#{order_cycle.id}", nil
        expect { cpr.products_json }.to raise_error ProductsRenderer::NoProducts
      end
    end

    describe "when the products JSON is not cached" do
      let(:cached_json) { Rails.cache.read "products-json-#{distributor.id}-#{order_cycle.id}" }
      let(:cache_present) { Rails.cache.exist? "products-json-#{distributor.id}-#{order_cycle.id}" }

      before do
        Rails.cache.clear
        cpr.stub(:uncached_products_json) { 'fresh products' }
      end

      describe "when there are products" do
        it "returns products as JSON" do
          expect(cpr.products_json).to eq 'fresh products'
        end

        it "caches the JSON" do
          cpr.products_json
          expect(cached_json).to eq 'fresh products'
        end
      end

      describe "when there are no products" do
        before { cpr.stub(:uncached_products_json).and_raise ProductsRenderer::NoProducts }

        it "raises an error" do
          expect { cpr.products_json }.to raise_error ProductsRenderer::NoProducts
        end

        it "caches the products as nil" do
          expect { cpr.products_json }.to raise_error ProductsRenderer::NoProducts
          expect(cache_present).to be
          expect(cached_json).to be_nil
        end
      end

      describe "logging a warning" do
        it "logs a warning when in production"
        it "logs a warning when in staging"
        it "does not log a warning in development"
        it "does not log a warning in test"
      end
    end

    describe "fetching uncached products from ProductsRenderer" do
      let(:pr) { double(:products_renderer, products_json: 'uncached products') }

      before do
        ProductsRenderer.stub(:new) { pr }
      end

      it "returns the uncached products" do
        expect(cpr.send(:uncached_products_json)).to eq 'uncached products'
      end
    end
  end
end
