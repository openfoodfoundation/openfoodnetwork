# frozen_string_literal: true

require 'system_helper'

RSpec.describe "As a consumer I want to view products" do
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
    let(:distributor) {
      create(:distributor_enterprise, with_payment_and_shipping: true, owner: user,
                                      name: "Testing Farm")
    }
    let(:supplier) { create(:supplier_enterprise) }
    let(:oc1) {
      create(:simple_order_cycle, distributors: [distributor],
                                  coordinator: create(:distributor_enterprise),
                                  orders_close_at: 2.days.from_now)
    }
    let(:product) {
      create(:simple_product, supplier_id: supplier.id, primary_taxon: taxon,
                              properties: [property], name: "Beans")
    }
    let(:product2) {
      create(:product, supplier_id: supplier.id, primary_taxon: taxon2, properties: [property2],
                       name: "Chickpeas")
    }
    let(:variant) { product.variants.first }
    let(:variant2) { product2.variants.first }
    let(:exchange1) { oc1.exchanges.to_enterprises(distributor).outgoing.first }
    let(:order) { create(:order, distributor:) }

    before do
      pick_order order
    end

    describe "supplier's name is displayed" do
      before do
        exchange1.update_attribute :pickup_time, "monday"
        add_variant_to_order_cycle(exchange1, variant)
      end

      it "shows supplier's name" do
        visit shop_path
        expect(page).to have_content supplier.name
        page.find("span", text: supplier.name).click
        assert_selector ".reveal-modal"
      end

      it "shows supplier's name even when supplier's visibility is hidden" do
        supplier.visible = 'hidden'
        supplier.save
        visit shop_path
        expect(page).to have_content supplier.name
        # Does not open the modal though
        page.find("span", text: supplier.name).click
        assert_no_selector ".reveal-modal"
      end
    end

    describe "viewing HTML product descriptions" do
      before do
        exchange1.update_attribute :pickup_time, "monday"
        add_variant_to_order_cycle(exchange1, variant)
      end

      it "shows HTML product description and truncates it correctly" do
        pending "#10685"
        product.description = '<p><b>Formatted</b> product description: Lorem ipsum dolor sit amet,
                              consectetur adipiscing elit. Morbi venenatis metus diam,
                               eget scelerisque nibh auctor non. </p> Link to an ' \
                              '<a href="http://google.fr">external site</a>' \
                              '<img src="https://www.openfoodnetwork.org/wp-content/uploads/2019/' \
                              '05/logo-ofn-global-web@2x.png" alt="open food network logo" />'
        product.save!

        visit shop_path
        expect(page).to have_content product.name

        # It truncates a long product description.
        within_product_description(product) do
          expect(html).to include "<b>Formatted</b> product description: Lorem ipsum"
          expect(page).to have_content "..."
        end
        within_product_modal(product) do
          expect(html).to include product.description
          expect(find_link('external site')[:target]).to eq('_blank')
        end
      end

      it "does not show unsecure HTML" do
        product.description = "<script>alert('Dangerous!');</script><p>Safe</p>"
        product.save!

        visit shop_path
        expect(page).to have_content product.name

        within_product_description(product) do
          expect(html).to include "<p>Safe</p>"
          expect(html).not_to include "<script>alert('Dangerous!');</script>"
          expect(page).to have_content "alert('Dangerous!'); Safe"
        end
        within_product_modal(product) do
          expect(html).to include "<p>Safe</p>"
          expect(html).not_to include "<script>alert('Dangerous!');</script>"
          expect(page).to have_content "alert('Dangerous!'); Safe"
        end
      end

      it "opens link in product description inside another window" do
        product.description = "<a href='https://api.rubyonrails.org/'>external site</a>"
        product.save!

        visit shop_path
        expect(find_link('external site')[:target]).to eq('_blank')
      end
    end

    describe "filtering" do
      before do
        exchange1.update_attribute :pickup_time, "monday"
        add_variant_to_order_cycle(exchange1, variant)
        add_variant_to_order_cycle(exchange1, variant2)
      end

      context "product taxons" do
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

  def within_product_modal(product, &)
    click_link product.name
    modal_should_be_open_for product
    within(".reveal-modal", &)
  end

  def within_product_description(product, &)
    within("#product-#{product.id} .product-description", &)
  end
end
