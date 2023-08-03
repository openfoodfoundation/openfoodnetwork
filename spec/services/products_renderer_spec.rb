# frozen_string_literal: true

require 'spec_helper'

describe ProductsRenderer do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
  let(:exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }
  let(:customer) { create(:customer) }
  let(:products_renderer) { ProductsRenderer.new(distributor, order_cycle, customer) }

  describe "sorting and filtering" do
    let(:fruits) { create(:taxon) }
    let(:cakes) { create(:taxon) }
    let(:fruits_supplier) { create(:supplier_enterprise) }
    let(:cakes_supplier) { create(:supplier_enterprise) }
    let!(:product_apples) {
      create(:product, name: "apples", primary_taxon_id: fruits.id,
                       supplier_id: fruits_supplier.id)
    }
    let!(:product_banana_bread) {
      create(:product, name: "banana bread", primary_taxon_id: cakes.id,
                       supplier_id: cakes_supplier.id)
    }
    let!(:product_cherries) {
      create(:product, name: "cherries", primary_taxon_id: fruits.id,
                       supplier_id: fruits_supplier.id)
    }
    let!(:product_doughnuts) {
      create(:product, name: "doughnuts", primary_taxon_id: cakes.id,
                       supplier_id: cakes_supplier.id)
    }

    before do
      exchange.variants << product_apples.variants.first
      exchange.variants << product_banana_bread.variants.first
      exchange.variants << product_cherries.variants.first
      exchange.variants << product_doughnuts.variants.first
    end

    describe "sorting" do
      it "sorts products by the distributor's preferred taxon list" do
        allow(distributor)
          .to receive(:preferred_shopfront_taxon_order) { "#{cakes.id},#{fruits.id}" }
        products = products_renderer.send(:products)
        expect(products)
          .to eq([product_banana_bread, product_doughnuts, product_apples, product_cherries])
      end

      it "sorts products by the distributor's preferred producer list" do
        allow(distributor)
          .to receive(:preferred_shopfront_product_sorting_method) { "by_producer" }
        allow(distributor).to receive(:preferred_shopfront_producer_order) {
          "#{cakes_supplier.id},#{fruits_supplier.id}"
        }
        products = products_renderer.send(:products)
        expect(products)
          .to eq([product_banana_bread, product_doughnuts, product_apples, product_cherries])
      end

      it "alphabetizes products by name when taxon list is not set" do
        allow(distributor).to receive(:preferred_shopfront_taxon_order) { "" }
        products = products_renderer.send(:products)
        expect(products)
          .to eq([product_apples, product_banana_bread, product_cherries, product_doughnuts])
      end
    end

    context "filtering" do
      it "filters products by name_or_meta_keywords_or_variants_display_as_or_" \
         "variants_display_name_or_supplier_name_cont" do
        products_renderer = ProductsRenderer.new(distributor, order_cycle, customer, { q: {
                                                   "#{[:name, :meta_keywords, :variants_display_as,
                                                       :variants_display_name, :supplier_name]
                                                   .join('_or_')}_cont": "apples",
                                                 } })
        products = products_renderer.send(:products)
        expect(products).to eq([product_apples])
      end

      context "when property is set" do
        let(:property_organic) { Spree::Property.create! name: 'Organic', presentation: 'Organic' }
        let(:property_conventional) {
          Spree::Property.create! name: 'Conventional', presentation: 'Conventional'
        }

        it "filters products with a product property" do
          product_apples.product_properties.create!({ property_id: property_organic.id,
                                                      value: '1', position: 1 })
          products_renderer = ProductsRenderer.new(distributor, order_cycle, customer,
                                                   { q: {
                                                     with_properties: [property_organic.id]
                                                   } })
          products = products_renderer.send(:products)
          expect(products).to eq([product_apples])
        end

        it "filters products with a producer property" do
          fruits_supplier.producer_properties.create!({ property_id: property_organic.id,
                                                        value: '1', position: 1 })
          products_renderer = ProductsRenderer.new(distributor, order_cycle, customer,
                                                   { q: {
                                                     with_properties: [property_organic.id]
                                                   } })
          products = products_renderer.send(:products)
          expect(products).to eq([product_apples, product_cherries])
        end

        it "filters products with property when sorting is enabled" do
          allow(distributor).to receive(:preferred_shopfront_taxon_order) {
            "#{fruits.id},#{cakes.id}"
          }
          product_apples.product_properties.create!({ property_id: property_conventional.id,
                                                      value: '1', position: 1 })
          product_banana_bread.product_properties.create!({ property_id: property_organic.id,
                                                            value: '1', position: 1 })
          product_cherries.product_properties.create!({ property_id: property_organic.id,
                                                        value: '1', position: 1 })
          product_doughnuts.product_properties.create!({ property_id: property_organic.id,
                                                         value: '1', position: 1 })
          products_renderer = ProductsRenderer.new(distributor, order_cycle, customer,
                                                   { q: {
                                                     with_properties: [property_organic.id]
                                                   } })
          products = products_renderer.send(:products)
          expect(products).to eq([product_cherries, product_banana_bread, product_doughnuts])
        end
      end
    end
  end

  context "JSON tests" do
    let(:product) { create(:product) }
    let(:variant) { product.variants.first }

    before do
      exchange.variants << variant
    end

    it "only returns products for the current order cycle" do
      expect(products_renderer.products_json).to include product.name
    end

    it "doesn't return products not in stock" do
      variant.update_attribute(:on_demand, false)
      variant.update_attribute(:on_hand, 0)
      expect(products_renderer.products_json).not_to include product.name
    end

    it "strips html from description" do
      product.update_attribute(:description, "<a href='44'>turtles</a> frogs")
      json = products_renderer.products_json
      expect(json).to include "frogs"
      expect(json).not_to include "<a href"
    end

    it "returns price including fees" do
      # Price is 19.99
      allow_any_instance_of(OpenFoodNetwork::EnterpriseFeeCalculator).
        to receive(:indexed_fees_for).and_return 978.01

      expect(products_renderer.products_json).to include "998.0"
    end

    it "includes the primary taxon" do
      taxon = create(:taxon)
      allow_any_instance_of(Spree::Product).to receive(:primary_taxon).and_return taxon
      expect(products_renderer.products_json).to include taxon.name
    end

    it "loads tag_list for variants" do
      VariantOverride.create(variant: variant, hub: distributor, tag_list: 'lalala')
      expect(products_renderer.products_json).to include "[\"lalala\"]"
    end
  end

  describe "loading variants" do
    let(:hub) { create(:distributor_enterprise) }
    let(:oc) { create(:simple_order_cycle, distributors: [hub], variants: [v1, v3, v4]) }
    let(:p) { create(:simple_product) }
    let!(:v1) {
      create(:variant, product: p, unit_value: 3)
    } # In exchange, not in inventory (ie. not_hidden)
    let!(:v2) { create(:variant, product: p, unit_value: 5) } # Not in exchange
    let!(:v3) {
      create(:variant, product: p, unit_value: 7,
                       inventory_items: [create(:inventory_item, enterprise: hub, visible: true)])
    }
    let!(:v4) {
      create(:variant, product: p, unit_value: 9,
                       inventory_items: [create(:inventory_item, enterprise: hub, visible: false)])
    }
    let(:products_renderer) { ProductsRenderer.new(hub, oc, customer) }
    let(:variants) { products_renderer.send(:variants_for_shop_by_id) }

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

      it "doesn't render variants that haven't been explicitly added to inventory for the hub" do
        # but does render 'new' variants, ie. v1
        expect(variants[p.id]).to include v3
        expect(variants[p.id]).to_not include v1, v4
      end
    end
  end
end
