# frozen_string_literal: true

require "spec_helper"

module Api
  describe V0::OrderCyclesController, type: :controller do
    let!(:distributor) { create(:distributor_enterprise) }
    let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
    let!(:exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }
    let!(:taxon1) { create(:taxon, name: 'Meat') }
    let!(:taxon2) { create(:taxon, name: 'Vegetables') }
    let!(:taxon3) { create(:taxon, name: 'Cake') }
    let!(:property1) { create(:property, presentation: 'Organic') }
    let!(:property2) { create(:property, presentation: 'Dairy-Free') }
    let!(:property3) { create(:property, presentation: 'May Contain Nuts') }
    let!(:product1) {
      create(:product, name: "Kangaroo", primary_taxon: taxon1, properties: [property1])
    }
    let!(:product2) {
      create(:product, name: "Parsnips", primary_taxon: taxon2, properties: [property2])
    }
    let!(:product3) { create(:product, primary_taxon: taxon2) }
    let!(:product4) { create(:product, primary_taxon: taxon3, properties: [property3]) }
    let!(:user) { create(:user) }
    let(:customer) { create(:customer, user: user, enterprise: distributor) }

    before do
      exchange.variants << product1.variants.first
      exchange.variants << product2.variants.first
      exchange.variants << product3.variants.first
      allow(controller).to receive(:spree_current_user) { user }
    end

    describe "#products" do
      it "loads products for distributed products in the order cycle" do
        api_get :products, id: order_cycle.id, distributor: distributor.id

        expect(product_ids).to include product1.id, product2.id, product3.id
      end

      it "returns products that were searched for" do
        ransack_param = "name_or_meta_keywords_or_variants_display_as_or_" \
                        "variants_display_name_or_supplier_name_cont"
        api_get :products, id: order_cycle.id, distributor: distributor.id,
                           q: { ransack_param => "Kangaroo" }

        expect(product_ids).to include product1.id
        expect(product_ids).to_not include product2.id
      end

      context "with variant overrides" do
        let!(:vo1) {
          create(:variant_override,
                 hub: distributor,
                 variant: product1.variants.first,
                 price: 1234.56)
        }
        let!(:vo2) {
          create(:variant_override,
                 hub: distributor,
                 variant: product2.variants.first,
                 count_on_hand: 0)
        }

        it "returns results scoped with variant overrides" do
          api_get :products, id: order_cycle.id, distributor: distributor.id

          overidden_product = json_response.select{ |product| product['id'] == product1.id }
          expect(overidden_product[0]['variants'][0]['price']).to eq vo1.price.to_s
        end

        it "does not return products where the variant overrides are out of stock" do
          api_get :products, id: order_cycle.id, distributor: distributor.id

          expect(product_ids).to_not include product2.id
        end
      end

      context "with property filters" do
        before do
          product1.update!(properties: [property1, property2])
        end

        it "filters by product property" do
          api_get :products, id: order_cycle.id, distributor: distributor.id,
                             q: { with_properties: [property1.id, property2.id] }

          expect(response.status).to eq 200
          expect(product_ids).to eq [product1.id, product2.id]
          expect(product_ids).to_not include product3.id
        end

        context "with supplier properties" do
          let!(:supplier_property) { create(:property, presentation: 'Certified Organic') }
          let!(:supplier) { create(:supplier_enterprise, properties: [supplier_property]) }

          before do
            product1.update!(supplier: supplier)
            product2.update!(supplier: supplier)
            product3.update!(supplier: supplier, inherits_properties: false)
          end

          it "filter out the product that don't inherits from supplier properties" do
            api_get :products, id: order_cycle.id, distributor: distributor.id,
                               q: { with_properties: [supplier_property.id] }

            expect(response.status).to eq 200
            expect(product_ids).to match_array [product1.id, product2.id]
            expect(product_ids).to_not include product3.id
          end
        end
      end

      context "with taxon filters" do
        it "filters by taxon" do
          api_get :products, id: order_cycle.id, distributor: distributor.id,
                             q: { primary_taxon_id_in_any: [taxon2.id] }

          expect(product_ids).to include product2.id, product3.id
          expect(product_ids).to_not include product1.id, product4.id
        end
      end

      context "when tag rules apply" do
        let!(:vo1) {
          create(:variant_override,
                 hub: distributor,
                 variant: product1.variants.first)
        }
        let!(:vo2) {
          create(:variant_override,
                 hub: distributor,
                 variant: product2.variants.first)
        }
        let!(:vo3) {
          create(:variant_override,
                 hub: distributor,
                 variant: product3.variants.first)
        }
        let(:default_hide_rule) {
          create(:filter_products_tag_rule,
                 enterprise: distributor,
                 is_default: true,
                 preferred_variant_tags: "hide_these_variants_from_everyone",
                 preferred_matched_variants_visibility: "hidden")
        }
        let!(:hide_rule) {
          create(:filter_products_tag_rule,
                 enterprise: distributor,
                 preferred_variant_tags: "hide_these_variants",
                 preferred_customer_tags: "hide_from_these_customers",
                 preferred_matched_variants_visibility: "hidden" )
        }
        let!(:show_rule) {
          create(:filter_products_tag_rule,
                 enterprise: distributor,
                 preferred_variant_tags: "show_these_variants",
                 preferred_customer_tags: "show_for_these_customers",
                 preferred_matched_variants_visibility: "visible" )
        }

        it "does not return variants hidden by general rules" do
          vo1.update_attribute(:tag_list, default_hide_rule.preferred_variant_tags)

          api_get :products, id: order_cycle.id, distributor: distributor.id

          expect(product_ids).to_not include product1.id
        end

        it "does not return variants hidden for this specific customer" do
          vo2.update_attribute(:tag_list, hide_rule.preferred_variant_tags)
          customer.update_attribute(:tag_list, hide_rule.preferred_customer_tags)

          api_get :products, id: order_cycle.id, distributor: distributor.id

          expect(product_ids).to_not include product2.id
        end

        it "returns hidden variants made visible for this specific customer" do
          vo1.update_attribute(:tag_list, default_hide_rule.preferred_variant_tags)
          vo3.update_attribute(:tag_list,
                               "#{show_rule.preferred_variant_tags}," \
                               "#{default_hide_rule.preferred_variant_tags}")
          customer.update_attribute(:tag_list, show_rule.preferred_customer_tags)

          api_get :products, id: order_cycle.id, distributor: distributor.id

          expect(product_ids).to_not include product1.id
          expect(product_ids).to include product3.id
        end
      end

      context "when the order cycle is closed" do
        before do
          allow(controller).to receive(:order_cycle) { order_cycle }
          allow(order_cycle).to receive(:open?) { false }
        end

        # Regression test for https://github.com/openfoodfoundation/openfoodnetwork/issues/6491
        it "renders no products without error" do
          api_get :products, id: order_cycle.id, distributor: distributor.id

          expect(json_response).to eq({})
          expect(response).to have_http_status :not_found
        end
      end
    end

    describe "#taxons" do
      it "loads taxons for distributed products in the order cycle" do
        api_get :taxons, id: order_cycle.id, distributor: distributor.id

        taxons = json_response.map{ |taxon| taxon['name'] }

        expect(json_response.length).to be 2
        expect(taxons).to include taxon1.name, taxon2.name
      end
    end

    describe "#properties" do
      it "loads properties for distributed products in the order cycle" do
        api_get :properties, id: order_cycle.id, distributor: distributor.id

        properties = json_response.map{ |property| property['name'] }

        expect(json_response.length).to be 2
        expect(properties).to include property1.presentation, property2.presentation
      end

      context "with producer properties" do
        let!(:property4) { create(:property) }
        let!(:producer_property) {
          create(:producer_property, producer_id: product1.supplier.id, property: property4)
        }

        it "loads producer properties for distributed products in the order cycle" do
          api_get :properties, id: order_cycle.id, distributor: distributor.id

          properties = json_response.map{ |property| property['name'] }

          expect(json_response.length).to be 3
          expect(properties).to include property1.presentation, property2.presentation,
                                        producer_property.property.presentation
        end
      end
    end

    context "with custom taxon ordering applied and duplicate product names in the order cycle" do
      let!(:supplier) { create(:supplier_enterprise) }
      let!(:product5) {
        create(:product, name: "Duplicate name", primary_taxon: taxon3, supplier: supplier)
      }
      let!(:product6) {
        create(:product, name: "Duplicate name", primary_taxon: taxon3, supplier: supplier)
      }
      let!(:product7) {
        create(:product, name: "Duplicate name", primary_taxon: taxon2, supplier: supplier)
      }
      let!(:product8) {
        create(:product, name: "Duplicate name", primary_taxon: taxon2, supplier: supplier)
      }

      before do
        distributor.preferred_shopfront_taxon_order = "#{taxon2.id},#{taxon3.id},#{taxon1.id}"
        exchange.variants << product5.variants.first
        exchange.variants << product6.variants.first
        exchange.variants << product7.variants.first
        exchange.variants << product8.variants.first
      end

      it "displays products in new order" do
        api_get :products, id: order_cycle.id, distributor: distributor.id
        expect(product_ids).to eq [product7.id, product8.id, product2.id, product3.id, product5.id,
                                   product6.id, product1.id]
      end

      it "displays products in correct order across multiple pages" do
        api_get :products, id: order_cycle.id, distributor: distributor.id, per_page: 3
        expect(product_ids).to eq [product7.id, product8.id, product2.id]

        api_get :products, id: order_cycle.id, distributor: distributor.id, per_page: 3, page: 2
        expect(product_ids).to eq [product3.id, product5.id, product6.id]

        api_get :products, id: order_cycle.id, distributor: distributor.id, per_page: 3, page: 3
        expect(product_ids).to eq [product1.id]
      end
    end

    private

    def product_ids
      json_response.map{ |product| product['id'] }
    end
  end
end
