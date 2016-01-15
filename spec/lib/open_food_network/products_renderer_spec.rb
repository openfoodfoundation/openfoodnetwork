require 'spec_helper'
require 'open_food_network/products_renderer'

module OpenFoodNetwork
  describe ProductsRenderer do
    let(:d) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, distributors: [d], coordinator: create(:distributor_enterprise)) }
    let(:exchange) { Exchange.find(order_cycle.exchanges.to_enterprises(d).outgoing.first.id) }
    let(:pr) { ProductsRenderer.new(d, order_cycle) }

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
        d.stub(:preferred_shopfront_taxon_order) {"#{t1.id},#{t2.id}"}
        products = pr.send(:products_for_shop)
        products.should == [p2, p4, p1, p3]
      end

      it "alphabetizes products by name when taxon list is not set" do
        d.stub(:preferred_shopfront_taxon_order) {""}
        products = pr.send(:products_for_shop)
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
        pr.products.should include product.name
      end

      it "doesn't return products not in stock" do
        variant.update_attribute(:count_on_hand, 0)
        pr.products.should_not include product.name
      end

      it "strips html from description" do
        product.update_attribute(:description, "<a href='44'>turtles</a> frogs")
        json = pr.products
        json.should include "frogs"
        json.should_not include "<a href"
      end

      it "returns price including fees" do
        # Price is 19.99
        OpenFoodNetwork::EnterpriseFeeCalculator.any_instance.
          stub(:indexed_fees_for).and_return 978.01

        pr.products.should include "998.0"
      end

      it "includes the primary taxon" do
        taxon = create(:taxon)
        Spree::Product.any_instance.stub(:primary_taxon).and_return taxon
        pr.products.should include taxon.name
      end
    end

    describe "loading variants" do
      let(:hub) { create(:distributor_enterprise) }
      let(:oc) { create(:simple_order_cycle, distributors: [hub], variants: [v1]) }
      let(:p) { create(:simple_product) }
      let!(:v1) { create(:variant, product: p, unit_value: 3) }
      let!(:v2) { create(:variant, product: p, unit_value: 5) }

      it "scopes variants to distribution" do
        pr = ProductsRenderer.new(hub, oc)
        pr.send(:variants_for_shop_by_id).should == {p.id => [v1]}
      end
    end
  end
end
