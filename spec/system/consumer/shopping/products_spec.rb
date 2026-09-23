# frozen_string_literal: true

require 'system_helper'

RSpec.describe "As a consumer I want to view products" do
  include AuthenticationHelper
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  describe "on their own pages", feature: :product_grid_view do
    let(:enterprise) {
      create(:distributor_enterprise, name: "The Garlic Guru", with_payment_and_shipping: true)
    }
    let(:producer) { create(:supplier_enterprise, name: "Onion Orchard") }
    let(:product) { create(:product, enterprise_id: enterprise.id, name: "Garlic") }
    let!(:big_bag) {
      create(:variant, product:, enterprise:, display_name: "Big bag", unit_value: 2000)
    }
    let!(:other_farm_bag) {
      create(:variant, product:, enterprise: producer, display_name: "Neighbour's bag")
    }
    let!(:order_cycle) {
      create(
        :simple_order_cycle,
        distributors: [enterprise], coordinator: enterprise,
        variants: product.variants,
        orders_close_at: 2.days.from_now
      )
    }

    it "lists all variants of the product" do
      visit enterprise_product_path(enterprise, product)

      expect(page).to have_content "Garlic"
      expect(page).to have_selector ".variant-list li", count: 3
      expect(page).to have_selector ".variant-name", text: "Big bag"
      expect(page).to have_selector ".variant-unit", text: "2kg"

      # Variants of several producers name their producer, the shared header doesn't.
      expect(page).to have_selector ".variant-producer", text: "From Onion Orchard"
      expect(page).to have_selector ".product-header", text: "Multiple producers"
    end

    # smoke test
    #
    # Adding to the cart needs an order cycle on the cart. Choosing one assigns it, but
    # with only one on offer there is nothing to choose, so the shop page has to do it.
    # Visiting the product page directly is the next step.
    it "and add a variant to the cart" do
      visit enterprise_shop_path(enterprise)
      expect(page).to have_content "Garlic"

      visit enterprise_product_path(enterprise, product)

      expect(page).to have_content "Garlic"

      within ".variant-list li", text: "Big bag" do
        click_button "Add"

        expect(page).to have_content "1 in cart"

        find("img[src*='add']").click

        expect(page).to have_content "2 in cart"
      end

      # The cart is saved for this shop, not just displayed.
      expect(page).to have_selector ".cart-span", text: "2"
      expect(Spree::LineItem.where(variant: big_bag).sum(:quantity)).to eq 2
    end

    context "with several order cycles to choose from" do
      let!(:later_order_cycle) {
        create(
          :simple_order_cycle,
          distributors: [enterprise], coordinator: enterprise,
          variants: [big_bag],
          orders_close_at: 4.days.from_now
        )
      }

      before do
        order_cycle.exchanges.to_enterprises(enterprise).outgoing.first
          .update!(pickup_time: "this week")
        later_order_cycle.exchanges.to_enterprises(enterprise).outgoing.first
          .update!(pickup_time: "next week")
      end

      it "lists the variants of the order cycle the shopper chooses" do
        visit enterprise_product_path(enterprise, product)

        expect(page).to have_content "Please choose an order cycle"
        expect(page).not_to have_selector ".variant-list"

        select "next week", from: "order_cycle_id"

        expect(page).to have_content "Next order closing in 4 days"
        expect(page).to have_selector ".variant-list li", count: 1
        expect(page).to have_selector ".variant-name", text: "Big bag"

        # The choice belongs to the cart, so the shopper can go on to fill it.
        expect(Spree::Order.last.distributor).to eq enterprise
        expect(Spree::Order.last.order_cycle).to eq later_order_cycle
      end

      it "asks before emptying the cart to change order cycle" do
        visit enterprise_product_path(enterprise, product)
        select "this week", from: "order_cycle_id"

        within ".variant-list li", text: "Big bag" do
          click_button "Add"
          expect(page).to have_content "1 in cart"
        end
        expect(page).to have_selector ".cart-span", text: "1"

        handle_js_confirm(false) do
          select "next week", from: "order_cycle_id"

          expect(page).to have_select "order_cycle_id", selected: "this week"
          expect(Spree::Order.last.order_cycle).to eq order_cycle
          expect(Spree::Order.last.line_items).to be_present
        end

        handle_js_confirm(true) do
          select "next week", from: "order_cycle_id"

          expect(page).to have_content "Next order closing in 4 days"
          expect(Spree::Order.last.order_cycle).to eq later_order_cycle
          expect(Spree::Order.last.line_items).to be_empty
        end
      end
    end

    context "when the shop has no open order cycle" do
      before { order_cycle.update!(orders_close_at: 1.day.ago) }

      it "says that the product is unavailable" do
        visit enterprise_product_path(enterprise, product)

        expect(page).to have_content "This product is currently unavailable."
        expect(page).not_to have_selector ".variant-list"
      end
    end
  end

  describe "Viewing a product" do
    let(:taxon) { create(:taxon, name: "Tricky Taxon") }
    let(:property) { create(:property, presentation: "Fresh and Fine") }
    let(:taxon2) { create(:taxon, name: "Delicious Dandelion") }
    let(:property2) { create(:property, presentation: "Berry Bio") }
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
      create(:simple_product, enterprise_id: supplier.id, primary_taxon: taxon,
                              properties: [property], name: "Beans")
    }
    let(:product2) {
      create(:product, enterprise_id: supplier.id, primary_taxon: taxon2, properties: [property2],
                       name: "Chickpeas")
    }
    let(:variant) { product.variants.first }
    let(:variant2) { product2.variants.first }
    let(:exchange1) { oc1.exchanges.to_enterprises(distributor).outgoing.first }
    let(:order) { create(:order, distributor:) }

    before do
      pick_order order
    end

    describe "producer name is displayed" do
      before do
        exchange1.update_attribute :pickup_time, "monday"
        add_variant_to_order_cycle(exchange1, variant)
      end

      it "shows enterprise name" do
        visit shop_path
        expect(page).to have_content "from Test Farm"
        page.find("span", text: "Test Farm").click
        assert_selector ".reveal-modal"
        expect(page).to have_content "ABOUT"
        expect(page).to have_content "Long Dsc"
      end

      it "shows enterprise name even when visibility is hidden" do
        supplier.visible = 'hidden'
        supplier.save
        visit shop_path
        expect(page).to have_content "from Test Farm"
        # Does not open the modal though
        page.find("span", text: "Test Farm").click
        assert_no_selector ".reveal-modal"
        expect(page).not_to have_content "Long Dsc"
      end

      context "with linked variant" do
        let(:source_variant) { create(:variant, enterprise: supplier) }

        before do
          # Producer grants distributor ability to create linked variant
          create(:enterprise_relationship, parent: supplier, child: distributor,
                                           permissions_list: [:create_linked_variants])
          source_variant.create_linked_variant(user)
        end

        it "shows source enterprise name" do
          visit shop_path
          expect(page).to have_content "from Test Farm"
          page.find("span", text: "Test Farm").click
          assert_selector ".reveal-modal"
          expect(page).to have_content "Long Dsc"
        end
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

      it "loads and clears the product modal in the dynamic modal container" do
        visit shop_path

        expect(page).not_to have_selector("#shop-product-modal-container .reveal-modal")

        open_product_modal(product)

        within("#shop-product-modal-container .reveal-modal") do
          expect(page).to have_content(product.name)
        end

        close_modal(within_selector: '#shop-product-modal-container')
        expect(page).not_to have_selector("#shop-product-modal-container .reveal-modal")
      end

      context "product grid view", feature: :product_grid_view do
        let(:other_supplier) { create(:supplier_enterprise, name: "Other Farm") }
        let(:product3) {
          create(:simple_product, enterprise_id: supplier.id, name: "Tomatoes")
        }
        let(:variant3) {
          product3.variants.first
        }
        let(:variant4) {
          create(:variant, product: product3, enterprise: other_supplier)
        }

        before do
          exchange1.update_attribute :pickup_time, "monday"
          add_variant_to_order_cycle(exchange1, variant)
          add_variant_to_order_cycle(exchange1, variant2)
          add_variant_to_order_cycle(exchange1, variant3)
          add_variant_to_order_cycle(exchange1, variant4)
        end

        it "displays products in a grid, with button for single variant product" do
          product.description = "<script>alert('Dangerous!');</script><p>Safe</p>"
          product.save!

          visit shop_path

          expect(page).to have_selector(".product-item", count: 3)
          expect(page).to have_content("Beans")
          expect(page).to have_content("Chickpeas")
          expect(page).to have_content("Tomatoes")

          within(".product-item", text: "Beans") do
            expect(page).to have_selector(".producer", text: "Test Farm")
            expect(page).to have_selector(".product-name", text: "Beans | ")
            expect(page).to have_selector(".price", text: "$19.99")
            expect(page).to have_selector(".unit-price")
          end

          # A product with mutiple producers and with several variants
          # - Multiple producers as producer name
          # - no single price or unit price to show,
          within(".product-item", text: "Tomatoes") do
            expect(page).to have_selector(".producer", text: "Multiple producers")
            expect(page).to have_selector(".product-name", text: "Tomatoes | multiple options")
            expect(page).to have_selector(".prices", text: /\Afrom \$/)
            expect(page).not_to have_selector(".unit-price")
          end

          # Add button is only displayed for single variant product
          expect(page).to have_selector(".add-variant", count: 2)

          # Product modal
          click_link product.name
          within(".reveal-modal") do
            expect(page).to have_content product.name

            # No insecure HTML
            expect(html).to include "<p>Safe</p>"
            expect(html).not_to include "<script>alert('Dangerous!');</script>"
            expect(page).to have_content "alert('Dangerous!'); Safe"

            # Product properties
            expect(page).to have_selector("span", text: "Fresh and Fine")
          end
        end
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
    open_product_modal(product)
    modal_should_be_open_for product
    within("#shop-product-modal-container .reveal-modal", &)
    close_modal(within_selector: '#shop-product-modal-container')
    expect(page).not_to have_selector("#shop-product-modal-container .reveal-modal")
  end

  def within_product_description(product, &)
    within("#product-#{product.id} .product-description", &)
  end
end
