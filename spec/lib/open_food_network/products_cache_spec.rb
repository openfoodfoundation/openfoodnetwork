require 'open_food_network/products_cache'

module OpenFoodNetwork
  describe ProductsCache do
    describe "when a variant changes" do
      let(:variant) { create(:variant) }
      let(:variant_undistributed) { create(:variant) }
      let(:supplier) { create(:supplier_enterprise) }
      let(:coordinator) { create(:distributor_enterprise) }
      let(:distributor) { create(:distributor_enterprise) }
      let(:oc_undated) { create(:undated_order_cycle, distributors: [distributor], variants: [variant]) }
      let(:oc_upcoming) { create(:upcoming_order_cycle, suppliers: [supplier], coordinator: coordinator, distributors: [distributor], variants: [variant]) }
      let(:oc_open) { create(:open_order_cycle, distributors: [distributor], variants: [variant]) }
      let(:oc_closed) { create(:closed_order_cycle, distributors: [distributor], variants: [variant]) }

      it "refreshes distributions with upcoming order cycles" do
        oc_upcoming
        expect(ProductsCache).to receive(:refresh_cache).with(distributor, oc_upcoming)
        ProductsCache.variant_changed variant
      end

      it "refreshes distributions with open order cycles" do
        oc_open
        expect(ProductsCache).to receive(:refresh_cache).with(distributor, oc_open)
        ProductsCache.variant_changed variant
      end

      it "does not refresh distributions with undated order cycles" do
        oc_undated
        expect(ProductsCache).not_to receive(:refresh_cache).with(distributor, oc_undated)
        ProductsCache.variant_changed variant
      end

      it "does not refresh distributions with closed order cycles" do
        oc_closed
        expect(ProductsCache).not_to receive(:refresh_cache).with(distributor, oc_closed)
        ProductsCache.variant_changed variant
      end

      it "limits refresh to outgoing exchanges" do
        oc_upcoming
        expect(ProductsCache).not_to receive(:refresh_cache).with(coordinator, oc_upcoming)
        ProductsCache.variant_changed variant
      end

      it "does not refresh distributions where the variant does not appear" do
        oc_undated; oc_upcoming; oc_open; oc_closed
        variant_undistributed
        expect(ProductsCache).not_to receive(:refresh_cache)
        ProductsCache.variant_changed variant_undistributed
      end
    end

    describe "refreshing the cache" do
      let(:distributor) { double(:distributor, id: 123) }
      let(:order_cycle) { double(:order_cycle, id: 456) }

      it "enqueues a RefreshProductsCacheJob" do
        expect do
          ProductsCache.send(:refresh_cache, distributor, order_cycle)
        end.to enqueue_job RefreshProductsCacheJob, distributor_id: distributor.id, order_cycle_id: order_cycle.id
      end
    end
  end
end
