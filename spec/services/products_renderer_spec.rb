# frozen_string_literal: true

RSpec.describe ProductsRenderer do
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
                       supplier_id: fruits_supplier.id, inherits_properties: true)
    }
    let!(:product_banana_bread) {
      create(:product, name: "banana bread", primary_taxon_id: cakes.id,
                       supplier_id: cakes_supplier.id, inherits_properties: true)
    }
    let!(:product_cherries) {
      create(:product, name: "cherries", primary_taxon_id: fruits.id,
                       supplier_id: fruits_supplier.id, inherits_properties: true)
    }
    let!(:product_doughnuts) {
      create(:product, name: "doughnuts", primary_taxon_id: cakes.id,
                       supplier_id: cakes_supplier.id, inherits_properties: true)
    }

    before do
      exchange.variants << product_apples.variants.first
      exchange.variants << product_banana_bread.variants.first
      exchange.variants << product_cherries.variants.first
      exchange.variants << product_doughnuts.variants.first
    end

    context "filtering" do
      it "filters products by name_or_meta_keywords_or_variants_display_as_or_" \
         "variants_display_name_or_variants_supplier_name_cont" do
        params = [:name, :meta_keywords, :variants_display_as, :variants_display_name,
                  :variants_supplier_name]
        ransack_param = "#{params.join('_or_')}_cont"
        products_renderer = ProductsRenderer.new(
          distributor,
          order_cycle,
          customer,
          { q: { "#{ransack_param}": "apples" } }
        )

        products = products_renderer.__send__(:products)
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
                                                     with_properties: [property_organic.id, 999]
                                                   } })
          products = products_renderer.__send__(:products)
          expect(products).to eq([product_apples])
        end

        it "filters products with a producer property" do
          fruits_supplier.producer_properties.create!({ property_id: property_organic.id,
                                                        value: '1', position: 1 })

          search_param = { q: { "with_variants_supplier_properties" => [property_organic.id] } }
          products_renderer = ProductsRenderer.new(distributor, order_cycle, customer, search_param)

          products = products_renderer.__send__(:products)
          expect(products).to eq([product_apples, product_cherries])
        end

        it "filters products with a product property or a producer property" do
          cakes_supplier.producer_properties.create!({ property_id: property_organic.id,
                                                       value: '1', position: 1 })
          product_apples.product_properties.create!({ property_id: property_conventional.id,
                                                      value: '1', position: 1 })

          search_param = { q:
            {
              "with_variants_supplier_properties" => [property_organic.id],
              "with_properties" => [property_conventional.id]
            } }
          products_renderer = ProductsRenderer.new(distributor, order_cycle, customer, search_param)

          products = products_renderer.__send__(:products)
          expect(products).to eq([product_apples, product_banana_bread, product_doughnuts])
        end

        it "filters product with property and taxon set" do
          stone_fruit = create(:taxon, name: "Stone fruit")
          product_peach =
            create(:product, name: "peach", primary_taxon_id: stone_fruit.id,
                             supplier_id: fruits_supplier.id, inherits_properties: true)

          fruits_supplier.producer_properties.create!({ property_id: property_organic.id,
                                                        value: '1', position: 1 })
          exchange.variants << product_peach.variants.first

          search_param = { q:
            {
              "with_variants_supplier_properties" => [property_organic.id],
              "variants_primary_taxon_id_in_any" => [stone_fruit.id],
            } }

          products_renderer = ProductsRenderer.new(distributor, order_cycle, customer, search_param)

          products = products_renderer.__send__(:products)
          expect(products).to eq([product_peach])
        end

        it "filters out products with inherits_properties set to false" do
          product_cherries.update!(inherits_properties: false)
          product_banana_bread.update!(inherits_properties: false)

          fruits_supplier.producer_properties.create!({ property_id: property_organic.id,
                                                        value: '1', position: 1 })

          search_param = { q: { "with_variants_supplier_properties" => [property_organic.id] } }
          products_renderer = ProductsRenderer.new(distributor, order_cycle, customer, search_param)

          products = products_renderer.__send__(:products)
          expect(products).to eq([product_apples])
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
          products = products_renderer.__send__(:products)
          expect(products).to eq([product_cherries, product_banana_bread, product_doughnuts])
        end

        it "filters products with producer properties when sorting is enabled" do
          allow(distributor).to receive(:preferred_shopfront_taxon_order) {
            "#{fruits.id},#{cakes.id}"
          }
          fruits_supplier.producer_properties.create!({ property_id: property_organic.id,
                                                        value: '1', position: 1 })
          search_param = { q: { "with_variants_supplier_properties" => [property_organic.id] } }
          products_renderer = ProductsRenderer.new(distributor, order_cycle, customer, search_param)

          products = products_renderer.__send__(:products)
          expect(products).to eq([product_apples, product_cherries])
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

    context "when inventory is enabled", feature: :inventory do
      it "loads tag_list for variants" do
        products_renderer = ProductsRenderer.new(distributor, order_cycle, customer, {},
                                                 inventory_enabled: true)
        VariantOverride.create(variant:, hub: distributor, tag_list: 'lalala')
        expect(products_renderer.products_json).to include "[\"lalala\"]"
      end

      it "loads variant override" do
        products_renderer = ProductsRenderer.new(distributor, order_cycle, customer, {},
                                                 inventory_enabled: true)
        VariantOverride.create(variant:, hub: distributor, price: 25.00)

        json = products_renderer.products_json
        first_variant = JSON.parse(json).first["variants"].first
        expect(first_variant["price_with_fees"]).to eq("25.0")
      end
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
    let(:variants) { products_renderer.__send__(:variants_for_shop_by_id) }

    it "scopes variants to distribution" do
      expect(variants[p.id]).to include v1
      expect(variants[p.id]).not_to include v2
    end

    it "does not render variants that have been hidden by the hub" do
      # but does render 'new' variants, ie. v1
      expect(variants[p.id]).to include v1, v3
      expect(variants[p.id]).not_to include v4
    end

    context "when hub opts to only see variants in its inventory" do
      before do
        allow(hub).to receive(:prefers_product_selection_from_inventory_only?) { true }
      end

      it "doesn't render variants that haven't been explicitly added to inventory for the hub" do
        # but does render 'new' variants, ie. v1
        expect(variants[p.id]).to include v3
        expect(variants[p.id]).not_to include v1, v4
      end
    end
  end
end
