require 'spec_helper'
require 'open_food_network/products_renderer'

module OpenFoodNetwork
  describe ProductsRenderer do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
    let(:exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }
    let(:pr) { ProductsRenderer.new(distributor, order_cycle) }

    describe "sorting" do
      let(:t1) { create(:taxon) }
      let(:t2) { create(:taxon) }
      let!(:p1) { create(:product, name: "abc", primary_taxon_id: t2.id) }
      let!(:p2) { create(:product, name: "def", primary_taxon_id: t1.id) }
      let!(:p3) { create(:product, name: "ghi", primary_taxon_id: t2.id) }
      let!(:p4) { create(:product, name: "jkl", primary_taxon_id: t1.id) }

      before do
        exchange.variants << p1.variants.first
        exchange.variants << p2.variants.first
        exchange.variants << p3.variants.first
        exchange.variants << p4.variants.first
      end

      it "sorts products by the distributor's preferred taxon list" do
        distributor.stub(:preferred_shopfront_taxon_order) {"#{t1.id},#{t2.id}"}
        products = pr.send(:load_products)
        products.should == [p2, p4, p1, p3]
      end

      it "alphabetizes products by name when taxon list is not set" do
        distributor.stub(:preferred_shopfront_taxon_order) {""}
        products = pr.send(:load_products)
        products.should == [p1, p2, p3, p4]
      end
    end

    context "JSON tests" do
      let(:product) { create(:product) }
      let(:variant) { product.variants.first }

      before do
        exchange.variants << variant
      end

      it "only returns products for the current order cycle" do
        pr.products_json.should include product.name
      end

      it "doesn't return products not in stock" do
        variant.update_attribute(:count_on_hand, 0)
        pr.products_json.should_not include product.name
      end

      it "strips html from description" do
        product.update_attribute(:description, "<a href='44'>turtles</a> frogs")
        json = pr.products_json
        json.should include "frogs"
        json.should_not include "<a href"
      end

      it "returns price including fees" do
        # Price is 19.99
        OpenFoodNetwork::EnterpriseFeeCalculator.any_instance.
          stub(:indexed_fees_for).and_return 978.01

        pr.products_json.should include "998.0"
      end

      it "includes the primary taxon" do
        taxon = create(:taxon)
        Spree::Product.any_instance.stub(:primary_taxon).and_return taxon
        pr.products_json.should include taxon.name
      end
    end

    describe "loading variants" do
      let(:hub) { create(:distributor_enterprise) }
      let(:oc) { create(:simple_order_cycle, distributors: [hub], variants: [v1, v3, v4]) }
      let(:p) { create(:simple_product) }
      let!(:v1) { create(:variant, product: p, unit_value: 3) } # In exchange, not in inventory (ie. not_hidden)
      let!(:v2) { create(:variant, product: p, unit_value: 5) } # Not in exchange
      let!(:v3) { create(:variant, product: p, unit_value: 7, inventory_items: [create(:inventory_item, enterprise: hub, visible: true)]) }
      let!(:v4) { create(:variant, product: p, unit_value: 9, inventory_items: [create(:inventory_item, enterprise: hub, visible: false)]) }
      let(:pr) { ProductsRenderer.new(hub, oc) }
      let(:variants) { pr.send(:variants_for_shop_by_id) }

      it "scopes variants to distribution" do
        expect(variants[p.id]).to include v1
        expect(variants[p.id]).to_not include v2
      end

      it "does not render variants that have been hidden by the hub" do
        # but does render 'new' variants, ie. v1
        expect(variants[p.id]).to include v1, v3
        expect(variants[p.id]).to_not include v4
      end


      context "when hub opts to only see variants in its inventory" do
        before do
          allow(hub).to receive(:prefers_product_selection_from_inventory_only?) { true }
        end

        it "does not render variants that have not been explicitly added to the inventory for the hub" do
          # but does render 'new' variants, ie. v1
          expect(variants[p.id]).to include v3
          expect(variants[p.id]).to_not include v1, v4
        end
      end
    end
  end
end
