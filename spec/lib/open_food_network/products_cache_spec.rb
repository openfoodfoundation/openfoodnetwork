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

    describe "when a variant is destroyed" do
      let(:variant) { create(:variant) }
      let(:distributor) { create(:distributor_enterprise) }
      let!(:oc) { create(:open_order_cycle, distributors: [distributor], variants: [variant]) }

      it "refreshes the cache based on exchanges the variant was in before destruction" do
        expect(ProductsCache).to receive(:refresh_cache).with(distributor, oc)
        variant.destroy
      end

      it "performs the cache refresh after the variant has been destroyed" do
        expect(ProductsCache).to receive(:refresh_cache).with(distributor, oc) do
          expect(Spree::Variant.where(id: variant.id)).to be_empty
        end

        variant.destroy
      end
    end

    describe "when a product changes" do
      let(:product) { create(:simple_product) }
      let(:v1) { create(:variant, product: product) }
      let(:v2) { create(:variant, product: product) }
      let(:d1) { create(:distributor_enterprise) }
      let(:d2) { create(:distributor_enterprise) }
      let(:oc) { create(:open_order_cycle) }
      let!(:ex1) { create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d1, variants: [v1]) }
      let!(:ex2) { create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d2, variants: [v1, v2]) }

      before { product.reload }

      it "refreshes the distribution each variant appears in, once each" do
        expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).once
        expect(ProductsCache).to receive(:refresh_cache).with(d2, oc).once
        ProductsCache.product_changed product
      end
    end

    describe "when a product is deleted" do
      let(:product) { create(:simple_product) }
      let(:variant) { create(:variant, product: product) }
      let(:distributor) { create(:distributor_enterprise) }
      let!(:oc) { create(:open_order_cycle, distributors: [distributor], variants: [variant]) }

      it "refreshes the cache based on exchanges the variant was in before destruction" do
        expect(ProductsCache).to receive(:refresh_cache).with(distributor, oc)
        product.delete
      end

      it "performs the cache refresh after the product has been removed from the order cycle" do
        expect(ProductsCache).to receive(:refresh_cache).with(distributor, oc) do
          expect(product.reload.deleted_at).not_to be_nil
        end

        product.delete
      end
    end

    describe "when a variant override changes" do
      let(:variant) { create(:variant) }
      let(:d1) { create(:distributor_enterprise) }
      let(:d2) { create(:distributor_enterprise) }
      let!(:vo) { create(:variant_override, variant: variant, hub: d1) }
      let!(:oc) { create(:open_order_cycle, distributors: [d1, d2], variants: [variant]) }

      it "refreshes the distributions that the variant override affects" do
        expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).once
        ProductsCache.variant_override_changed vo
      end

      it "does not refresh other distributors of the variant" do
        expect(ProductsCache).to receive(:refresh_cache).with(d2, oc).never
        ProductsCache.variant_override_changed vo
      end
    end


    describe "when a variant override is destroyed" do
      let(:vo) { double(:variant_override) }

      it "performs the same refresh as a variant override change" do
        expect(ProductsCache).to receive(:variant_override_changed).with(vo)
        ProductsCache.variant_override_destroyed vo
      end
    end


    describe "when a producer property is changed" do
      let(:s) { create(:supplier_enterprise) }
      let(:pp) { s.producer_properties.last }
      let(:product) { create(:simple_product, supplier: s) }
      let(:v1) { create(:variant, product: product) }
      let(:v2) { create(:variant, product: product) }
      let(:v_deleted) { create(:variant, product: product, deleted_at: Time.now) }
      let(:d1) { create(:distributor_enterprise) }
      let(:d2) { create(:distributor_enterprise) }
      let(:d3) { create(:distributor_enterprise) }
      let(:oc) { create(:open_order_cycle) }
      let!(:ex1) { create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d1, variants: [v1]) }
      let!(:ex2) { create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d2, variants: [v1, v2]) }
      let!(:ex3) { create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d3, variants: [product.master, v_deleted]) }

      before do
        s.set_producer_property :organic, 'NASAA 12345'
      end

      it "refreshes the distributions the supplied variants appear in" do
        expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).once
        expect(ProductsCache).to receive(:refresh_cache).with(d2, oc).once
        ProductsCache.producer_property_changed pp
      end

      it "doesn't respond to master or deleted variants" do
        expect(ProductsCache).to receive(:refresh_cache).with(d3, oc).never
        ProductsCache.producer_property_changed pp
      end
    end


    describe "when a producer property is destroyed" do
      let(:producer_property) { double(:producer_property) }

      it "triggers the same update as a change to the producer property" do
        expect(ProductsCache).to receive(:producer_property_changed).with(producer_property)
        ProductsCache.producer_property_destroyed producer_property
      end
    end


    describe "when an order cycle is changed" do
      let(:variant) { create(:variant) }
      let(:s) { create(:supplier_enterprise) }
      let(:c) { create(:distributor_enterprise) }
      let(:d1) { create(:distributor_enterprise) }
      let(:d2) { create(:distributor_enterprise) }
      let!(:oc_open) { create(:open_order_cycle, suppliers: [s], coordinator: c, distributors: [d1, d2], variants: [variant]) }
      let!(:oc_upcoming) { create(:upcoming_order_cycle, suppliers: [s], coordinator: c, distributors: [d1, d2], variants: [variant]) }

      before do
        oc_open.reload
        oc_upcoming.reload
      end

      it "updates each outgoing distribution in an upcoming order cycle" do
        expect(ProductsCache).to receive(:refresh_cache).with(d1, oc_upcoming).once
        expect(ProductsCache).to receive(:refresh_cache).with(d2, oc_upcoming).once
        ProductsCache.order_cycle_changed oc_upcoming
      end

      it "updates each outgoing distribution in an open order cycle" do
        expect(ProductsCache).to receive(:refresh_cache).with(d1, oc_open).once
        expect(ProductsCache).to receive(:refresh_cache).with(d2, oc_open).once
        ProductsCache.order_cycle_changed oc_open
      end

      it "does nothing when the order cycle has been made undated" do
        expect(ProductsCache).to receive(:refresh_cache).never
        oc_open.orders_open_at = oc_open.orders_close_at = nil
        oc_open.save!
      end

      it "does nothing when the order cycle has been closed" do
        expect(ProductsCache).to receive(:refresh_cache).never
        oc_open.orders_open_at = 2.weeks.ago
        oc_open.orders_close_at = 1.week.ago
        oc_open.save!
      end

      it "does not update incoming exchanges" do
        expect(ProductsCache).to receive(:refresh_cache).with(c, oc_open).never
        ProductsCache.order_cycle_changed oc_open
      end
    end


    describe "when an exchange is changed" do
      let(:s) { create(:supplier_enterprise) }
      let(:c) { create(:distributor_enterprise) }
      let(:d1) { create(:distributor_enterprise) }
      let(:d2) { create(:distributor_enterprise) }
      let(:v) { create(:variant) }
      let(:oc) { create(:open_order_cycle, coordinator: c) }

      describe "incoming exchanges" do
        let!(:ex1) { create(:exchange, order_cycle: oc, sender: s, receiver: c, incoming: true, variants: [v]) }
        let!(:ex2) { create(:exchange, order_cycle: oc, sender: c, receiver: d1, incoming: false, variants: [v]) }
        let!(:ex3) { create(:exchange, order_cycle: oc, sender: c, receiver: d2, incoming: false, variants: []) }

        before { oc.reload }

        it "updates distributions that include one of the supplier's variants" do
          expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).once
          ProductsCache.exchange_changed ex1
        end

        it "doesn't update distributions that don't include any of the supplier's variants" do
          expect(ProductsCache).to receive(:refresh_cache).with(d2, oc).never
          ProductsCache.exchange_changed ex1
        end
      end

      describe "outgoing exchanges" do
        let!(:ex) { create(:exchange, order_cycle: oc, sender: c, receiver: d1, incoming: false) }

        it "does not update for undated order cycles" do
          oc.update_attributes! orders_open_at: nil, orders_close_at: nil
          expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).never
          ProductsCache.exchange_changed ex
        end

        it "updates for upcoming order cycles" do
          oc.update_attributes! orders_open_at: 1.week.from_now, orders_close_at: 2.weeks.from_now
          expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).once
          ProductsCache.exchange_changed ex
        end

        it "updates for open order cycles" do
          expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).once
          ProductsCache.exchange_changed ex
        end

        it "does not update for closed order cycles" do
          oc.update_attributes! orders_open_at: 2.weeks.ago, orders_close_at: 1.week.ago
          expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).never
          ProductsCache.exchange_changed ex
        end
      end
    end


    describe "when an exchange is destroyed" do
      let(:exchange) { double(:exchange) }

      it "triggers the same update as a change to the exchange" do
        expect(ProductsCache).to receive(:exchange_changed).with(exchange)
        ProductsCache.exchange_destroyed exchange
      end
    end


    describe "when an enterprise fee is changed" do
      let(:s) { create(:supplier_enterprise) }
      let(:c) { create(:distributor_enterprise) }
      let(:d1) { create(:distributor_enterprise) }
      let(:d2) { create(:distributor_enterprise) }
      let(:ef) { create(:enterprise_fee) }
      let(:ef_coord) { create(:enterprise_fee, order_cycles: [oc]) }
      let(:oc) { create(:open_order_cycle, coordinator: c) }


      describe "updating exchanges when it's a supplier fee" do
        let(:v) { create(:variant) }
        let!(:ex1) { create(:exchange, order_cycle: oc, sender: s, receiver: c, incoming: true, variants: [v], enterprise_fees: [ef]) }
        let!(:ex2) { create(:exchange, order_cycle: oc, sender: c, receiver: d1, incoming: false, variants: [v]) }
        let!(:ex3) { create(:exchange, order_cycle: oc, sender: c, receiver: d2, incoming: false, variants: []) }

        before { ef.reload }

        describe "updating distributions that include one of the supplier's variants" do
          it "does not update undated order cycles" do
            oc.update_attributes! orders_open_at: nil, orders_close_at: nil
            expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).never
            ProductsCache.enterprise_fee_changed ef
          end

          it "updates upcoming order cycles" do
            oc.update_attributes! orders_open_at: 1.week.from_now, orders_close_at: 2.weeks.from_now
            expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).once
            ProductsCache.enterprise_fee_changed ef
          end

          it "updates open order cycles" do
            expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).once
            ProductsCache.enterprise_fee_changed ef
          end

          it "does not update closed order cycles" do
            oc.update_attributes! orders_open_at: 2.weeks.ago, orders_close_at: 1.week.ago
            expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).never
            ProductsCache.enterprise_fee_changed ef
          end
        end

        it "doesn't update distributions that don't include any of the supplier's variants" do
          expect(ProductsCache).to receive(:refresh_cache).with(d2, oc).never
          ProductsCache.enterprise_fee_changed ef
        end
      end


      it "updates order cycles when it's a coordinator fee" do
        ef_coord
        expect(ProductsCache).to receive(:order_cycle_changed).with(oc).once
        ProductsCache.enterprise_fee_changed ef_coord
      end


      describe "updating exchanges when it's a distributor fee" do
        let(:ex0) { create(:exchange, order_cycle: oc, sender: s, receiver: c, incoming: true, enterprise_fees: [ef]) }
        let(:ex1) { create(:exchange, order_cycle: oc, sender: c, receiver: d1, incoming: false, enterprise_fees: [ef]) }
        let(:ex2) { create(:exchange, order_cycle: oc, sender: c, receiver: d2, incoming: false, enterprise_fees: []) }

        describe "updating distributions that include the fee" do
          it "does not update undated order cycles" do
            oc.update_attributes! orders_open_at: nil, orders_close_at: nil
            ex1
            expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).never
            ProductsCache.enterprise_fee_changed ef
          end

          it "updates upcoming order cycles" do
            oc.update_attributes! orders_open_at: 1.week.from_now, orders_close_at: 2.weeks.from_now
            ex1
            expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).once
            ProductsCache.enterprise_fee_changed ef
          end

          it "updates open order cycles" do
            ex1
            expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).once
            ProductsCache.enterprise_fee_changed ef
          end

          it "does not update closed order cycles" do
            oc.update_attributes! orders_open_at: 2.weeks.ago, orders_close_at: 1.week.ago
            ex1
            expect(ProductsCache).to receive(:refresh_cache).with(d1, oc).never
            ProductsCache.enterprise_fee_changed ef
          end
        end

        it "doesn't update exchanges that don't include the fee" do
          ex1; ex2
          expect(ProductsCache).to receive(:refresh_cache).with(d2, oc).never
          ProductsCache.enterprise_fee_changed ef
        end

        it "doesn't update incoming exchanges" do
          ex0
          expect(ProductsCache).to receive(:refresh_cache).with(c, oc).never
          ProductsCache.enterprise_fee_changed ef
        end
      end
    end

    describe "when a distributor enterprise is changed" do
      let(:d) { create(:distributor_enterprise) }
      let(:oc) { create(:open_order_cycle, distributors: [d]) }

      it "updates each distribution the enterprise is active in" do
        expect(ProductsCache).to receive(:refresh_cache).with(d, oc)
        ProductsCache.distributor_changed d
      end
    end

    describe "when an inventory item is changed" do
      let!(:d) { create(:distributor_enterprise) }
      let!(:v) { create(:variant) }
      let!(:oc1) { create(:open_order_cycle, distributors: [d], variants: [v]) }
      let(:oc2) { create(:open_order_cycle, distributors: [d], variants: []) }
      let!(:ii) { create(:inventory_item, enterprise: d, variant: v) }

      it "updates each distribution for that enterprise+variant" do
        expect(ProductsCache).to receive(:refresh_cache).with(d, oc1)
        ProductsCache.inventory_item_changed ii
      end

      it "doesn't update distributions that don't feature the variant" do
        oc2
        expect(ProductsCache).to receive(:refresh_cache).with(d, oc2).never
        ProductsCache.inventory_item_changed ii
      end
    end

    describe "refreshing the cache" do
      let(:distributor) { double(:distributor) }
      let(:order_cycle) { double(:order_cycle) }

      it "notifies ProductsCacheRefreshment" do
        expect(ProductsCacheRefreshment).to receive(:refresh).with(distributor, order_cycle)
        ProductsCache.send(:refresh_cache, distributor, order_cycle)
      end
    end
  end
end
