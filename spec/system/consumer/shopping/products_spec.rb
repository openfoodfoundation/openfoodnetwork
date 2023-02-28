# frozen_string_literal: true

require 'system_helper'

describe "As a consumer I want to view products" do
  include AuthenticationHelper
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  describe "Viewing a product" do
    let(:taxon) { create(:taxon, name: "Tricky Taxon") }
    let(:property) { create(:property, presentation: "Fresh and Fine") }
    let(:taxon2) { create(:taxon, name: "Delicious Dandelion") }
    let(:property2) { create(:property, presentation: "Berry Bio") }
    let(:user) { create(:user, enterprise_limit: 1) }
    let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true, owner: user, name: "Testing Farm") }
    let(:supplier) { create(:supplier_enterprise) }
    let(:oc1) {
      create(:simple_order_cycle, distributors: [distributor],
                                  coordinator: create(:distributor_enterprise), orders_close_at: 2.days.from_now)
    }
    let(:product) {
      create(:simple_product, supplier: supplier, primary_taxon: taxon, properties: [property], name: "Beans")
    }
    let(:product2) {
      create(:product, supplier: supplier, primary_taxon: taxon2, properties: [property2], name: "Chickpeas")
    }
    let(:variant) { product.variants.first }
    let(:variant2) { product2.variants.first }
    let(:exchange1) { oc1.exchanges.to_enterprises(distributor).outgoing.first }
    let(:order) { create(:order, distributor: distributor) }

    before do
      set_order order
    end

    describe "viewing HTML product descriptions" do
      before do
        exchange1.update_attribute :pickup_time, "monday"
        add_variant_to_order_cycle(exchange1, variant)
      end

      it "shows HTML product description" do
        product.description = '<p><b>Formatted</b> product description.</p> Link to an <a href="http://google.fr" target="_blank">external site</a><img src="https://www.openfoodnetwork.org/wp-content/uploads/2019/05/logo-ofn-global-web@2x.png" alt="open food network logo" />'
        product.save!

        visit shop_path
        expect(page).to have_content product.name

        expect_product_description_html_to_be_displayed(product, product.description)
      end

      it "does not show unsecure HTML" do
        product.description = "<script>alert('Dangerous!');</script><p>Safe</p>"
        product.save!

        visit shop_path
        expect(page).to have_content product.name

        expect_product_description_html_to_be_displayed(product, "<p>Safe</p>", "<script>alert('Dangerous!');</script>")
      end
    end

    describe "filtering" do
      before do
        exchange1.update_attribute :pickup_time, "monday"
        add_variant_to_order_cycle(exchange1, variant)
        add_variant_to_order_cycle(exchange1, variant2)
      end

      context "product taxonomies" do
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

        it "filters out variants according to the selected property" do
          expect(page).to have_content variant.name.to_s
          expect(page).to have_content variant2.name.to_s

          within "#shop-tabs .sticky-shop-filters-container .property-selectors" do
            expect(page).to have_content "Fresh and Fine"
            toggle_filter property.presentation
          end

          expect(page).to have_content variant.name.to_s
          expect(page).not_to have_content variant2.name.to_s
        end
      end
    end
  end

  def expect_product_description_html_to_be_displayed(product, html, not_include = nil)
    # check inside list of products
    within "#product-#{product.id} .product-description" do
      expect(html).to include(html)
      expect(html).not_to include(not_include) if not_include
    end

    # check in product description modal
    click_link product.name
    expect(page).to have_selector '.reveal-modal'
    modal_should_be_open_for product
    within(".reveal-modal") do
      expect(html).to include(html)
      expect(html).not_to include(not_include) if not_include
    end
  end
end
