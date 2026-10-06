# frozen_string_literal: true

require 'system_helper'

RSpec.describe "As a consumer I want to view products" do
  include AuthenticationHelper
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  describe "filtering search results" do
    let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let(:supplier) { create(:supplier_enterprise, name: 'The small mammals company') }
    let(:oc1) {
      create(:simple_order_cycle, distributors: [distributor],
                                  coordinator: create(:distributor_enterprise),
                                  orders_close_at: 2.days.from_now)
    }
    let(:oc2) {
      create(:simple_order_cycle, distributors: [distributor],
                                  coordinator: create(:distributor_enterprise),
                                  orders_close_at: 3.days.from_now)
    }
    let(:product) { create(:simple_product, enterprise_id: supplier.id, meta_keywords: "Domestic") }
    let(:variant) { product.variants.first }
    let(:order) { create(:order, distributor:) }

    let(:variant1) { create(:variant, product:, price: 20) }
    let(:variant2) do
      create(:variant, product:, price: 30, display_name: "Badgers",
                       display_as: 'displayedunderthename')
    end
    let(:product2) {
      create(:simple_product, enterprise_id: supplier.id, name: "Meercats",
                              meta_keywords: "Wild Fresh")
    }
    let(:variant3) {
      create(:variant, product: product2, enterprise: supplier, price: 40,
                       display_name: "Ferrets")
    }
    let(:exchange) { Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) }

    before do
      pick_order order
    end

    before do
      add_variant_to_order_cycle(exchange, variant)
      add_variant_to_order_cycle(exchange, variant1)
      add_variant_to_order_cycle(exchange, variant2)
      add_variant_to_order_cycle(exchange, variant3)
      order.order_cycle = oc1
    end

    it "returns results when successful" do
      visit shop_path
      # When we see the Add button, it means product are loaded on the page
      expect(page).to have_content("Add", count: 4)

      fill_in "search", with: "74576345634XXXXXX"
      expect(page).to have_content "Sorry, no results found"
      expect(page).not_to have_content 'Meercats'

      click_on "Clear search" # clears search by clicking text
      expect(page).to have_content("Add", count: 4)

      fill_in "search", with: "Meer" # For product named "Meercats"
      expect(page).to have_content 'Meercats'
      expect(page).not_to have_content product.name

      find("a.clear").click # clears search by clicking the X button
      expect(page).to have_content("Add", count: 4)
    end

    it "returns results by looking at different columns in DB" do
      visit shop_path
      # When we see the Add button, it means product are loaded on the page
      expect(page).to have_content("Add", count: 4)

      # by keyword model: meta_keywords
      fill_in "search", with: "Wild" # For product named "Meercats"
      expect(page).to have_content 'Wild'
      find("a.clear").click

      # by variant display name model: variant display_name
      fill_in "search", with: "Ferrets" # For variants named "Ferrets"
      within('div.pad-top') do
        expect(page).to have_content 'Ferrets'
        expect(page).not_to have_content 'Badgers'
      end

      # model: variant display_as
      fill_in "search", with: "displayedunder" # "Badgers"
      within('div.pad-top') do
        expect(page).not_to have_content 'Ferrets'
        expect(page).to have_content 'Badgers'
      end

      # model: Enterprise name
      fill_in "search", with: "Enterp" # Enterprise 1 sells nothing
      within('p.no-results') do
        expect(page).to have_content "Sorry, no results found for Enterp"
      end
    end

    it "returns search results for products where the search term matches one of the product's " \
       "variant names" do
      visit shop_path
      fill_in "search", with: "Badg" # For variant with display_name "Badgers"

      within('div.pad-top') do
        expect(page).not_to have_content product2.name
        expect(page).not_to have_content variant3.display_name
        expect(page).to have_content product.name
        expect(page).to have_content variant2.display_name
      end
    end
  end

  describe "product taxons (categories)" do
    let(:taxon) { create(:taxon, name: "Tricky Taxon") }
    let(:taxon2) { create(:taxon, name: "Delicious Dandelion") }
    let(:user) { create(:user, enterprise_limit: 1) }
    let(:distributor) {
      create(:distributor_enterprise, with_payment_and_shipping: true, owner: user,
                                      name: "Testing Distributor")
    }
    let(:supplier) { create(:supplier_enterprise, name: "Test Farm", long_description: "Long Dsc") }
    let(:oc1) {
      create(:simple_order_cycle, distributors: [distributor],
                                  coordinator: create(:distributor_enterprise),
                                  orders_close_at: 2.days.from_now)
    }
    let(:product) {
      create(:simple_product, enterprise_id: supplier.id, primary_taxon: taxon, name: "Beans")
    }
    let(:product2) {
      create(:product, enterprise_id: supplier.id, primary_taxon: taxon2, name: "Chickpeas")
    }
    let(:variant) { product.variants.first }
    let(:variant2) { product2.variants.first }
    let(:exchange1) { oc1.exchanges.to_enterprises(distributor).outgoing.first }
    let(:order) { create(:order, distributor:) }

    before do
      pick_order order
    end

    before do
      add_variant_to_order_cycle(exchange1, variant)
      add_variant_to_order_cycle(exchange1, variant2)
    end

    before do
      distributor.preferred_shopfront_product_sorting_method = "by_category"
      distributor.preferred_shopfront_taxon_order = taxon.id.to_s
      visit shop_path
    end

    it "filters out variants according to the selected taxon" do
      expect(page).to have_content variant.name.to_s
      expect(page).to have_content variant2.name.to_s

      within "#shop-tabs .taxon-selectors" do
        expect(page).to have_content "Tricky Taxon"
        toggle_filter taxon.name
      end

      expect(page).to have_content variant.name.to_s
      expect(page).not_to have_content variant2.name.to_s
    end

    context "when a product has variants in different taxons" do
      let!(:variant_in_taxon2) {
        create(:variant, product:, primary_taxon: taxon2, display_name: "Dandelion Beans")
      }

      before do
        add_variant_to_order_cycle(exchange1, variant_in_taxon2)
        visit shop_path
      end

      it "only shows the variants matching the selected taxon" do
        expect(page).to have_content "Dandelion Beans"

        within "#shop-tabs .taxon-selectors" do
          toggle_filter taxon.name
        end

        expect(page).to have_content "Beans"
        expect(page).not_to have_content "Dandelion Beans"
        expect(page).not_to have_content "Chickpeas"

        within "#shop-tabs .taxon-selectors" do
          toggle_filter taxon.name
          toggle_filter taxon2.name
        end

        expect(page).to have_content "Dandelion Beans"
        expect(page).to have_content "Chickpeas"
      end
    end
  end

  describe "properties" do
    let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let(:supplier) { create(:supplier_enterprise) }
    let(:supplier2) { create(:supplier_enterprise, properties: [producer_property]) }
    let(:oc1) {
      create(:simple_order_cycle, distributors: [distributor],
                                  coordinator: create(:distributor_enterprise),
                                  orders_close_at: 2.days.from_now)
    }
    let(:exchange) { Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) }
    let(:order) { create(:order, distributor:) }

    let(:product_property) { create(:property, presentation: "Bountiful product") }
    let(:product) {
      create(:simple_product, enterprise_id: supplier.id, name: "Bananas",
                              properties: [product_property])
    }
    let(:variant) { product.variants.first }

    let(:producer_property) { create(:property, presentation: "Aromatic producer") }
    let(:product2) {
      create(:simple_product, enterprise_id: supplier2.id, name: "Apples",
                              inherits_properties: true)
    }
    let(:variant2) { product2.variants.first }

    before do
      add_variant_to_order_cycle(exchange, variant)
      add_variant_to_order_cycle(exchange, variant2)
      order.order_cycle = oc1
      pick_order order
    end

    context "old angular view" do
      context "a product doesn't inherit producer properties" do
        let(:product2a) {
          create(:simple_product, enterprise_id: supplier2.id, name: "Avocados",
                                  inherits_properties: false)
        }
        let(:variant2a) { product2a.variants.first }

        before do
          add_variant_to_order_cycle(exchange, variant2a)
          visit shop_path
        end

        it "filters products by producer property" do
          click_filter "Aromatic producer"

          expect(page).to have_content "Apples"
          expect(page).not_to have_content "Avocados"
          expect(page).not_to have_content "Bananas"
        end
      end

      it "filters products by product property" do
        visit shop_path
        click_filter "Bountiful product"

        expect(page).not_to have_content "Apples"
        expect(page).to have_content "Bananas"
      end

      it "shows products from all selected properties" do
        visit shop_path
        click_filter "Aromatic producer"
        click_filter "Bountiful product"

        expect(page).to have_content "Apples"
        expect(page).to have_content "Bananas"
      end
    end
  end
end

def click_filter(name)
  # For now, look for `a` element inside the "Filter by" area.
  within find(".sticky-shop-filters-container", text: "Filter by") do
    find("a", text: name).click
  end
end
