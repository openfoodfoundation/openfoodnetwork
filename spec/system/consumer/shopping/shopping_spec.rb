# frozen_string_literal: true

require 'system_helper'

describe "As a consumer I want to shop with a distributor" do
  include AuthenticationHelper
  include FileHelper
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  describe "Viewing a distributor" do
    let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let(:supplier) { create(:supplier_enterprise) }
    let(:oc1) {
      create(:simple_order_cycle, distributors: [distributor],
                                  coordinator: create(:distributor_enterprise), orders_close_at: 2.days.from_now)
    }
    let(:oc2) {
      create(:simple_order_cycle, distributors: [distributor],
                                  coordinator: create(:distributor_enterprise), orders_close_at: 3.days.from_now)
    }
    let(:product) { create(:simple_product, supplier: supplier, meta_keywords: "Domestic") }
    let(:variant) { product.variants.first }
    let(:order) { create(:order, distributor: distributor) }

    before do
      set_order order
    end

    it "shows a distributor with images" do
      # Given the distributor has a logo
      distributor.update!(logo: white_logo_file)
      # Then we should see the distributor and its logo
      visit shop_path
      expect(page).to have_text distributor.name
      within ".tab-buttons" do
        click_link "About"
      end
      expect(first("distributor img")['src']).to include "logo-white.png"
    end

    it "shows the producers for a distributor" do
      exchange = Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id)
      add_variant_to_order_cycle(exchange, variant)

      visit shop_path
      within ".tab-buttons" do
        click_link "Producers"
      end
      expect(page).to have_content supplier.name
    end

    describe "selecting an order cycle" do
      let(:exchange1) { oc1.exchanges.to_enterprises(distributor).outgoing.first }

      describe "with only one open order cycle" do
        before { exchange1.update_attribute :pickup_time, "turtles" }

        it "selects an order cycle" do
          visit shop_path
          expect(page).to have_selector "p", text: 'turtles'
          expect(page).not_to have_content "choose when you want your order"
          expect(page).to have_content "Next order closing in 2 days"
        end

        describe "when order cycle closes in more than 3 months" do
          before { oc1.update orders_close_at: 5.months.from_now }

          it "shows alternative to 'closing in' message" do
            visit shop_path
            expect(page).to have_content "Orders are currently open"
          end
        end
      end

      describe "with multiple order cycles" do
        let(:exchange2) { oc2.exchanges.to_enterprises(distributor).outgoing.first }

        before do
          exchange1.update_attribute :pickup_time, "frogs"
          exchange2.update_attribute :pickup_time, "turtles"
        end

        it "shows a select with all order cycles, but doesn't show the products by default" do
          visit shop_path

          expect(page).to have_selector "option", text: 'frogs'
          expect(page).to have_selector "option", text: 'turtles'
          expect(page).to have_content "choose when you want your order"
          expect(page).not_to have_selector("input.button.right")
        end

        it "shows products after selecting an order cycle" do
          variant.update_attribute(:display_name, "kitten")
          variant.update_attribute(:display_as, "rabbit")
          add_variant_to_order_cycle(exchange1, variant)
          visit shop_path
          expect(page).not_to have_content product.name
          expect(Spree::Order.last.order_cycle).to be_nil

          select "frogs", from: "order_cycle_id"
          expect(page).to have_selector "products"
          expect(page).to have_content "Next order closing in 2 days"
          expect(Spree::Order.last.order_cycle).to eq(oc1)
          expect(page).to have_content product.name
          expect(page).to have_content variant.display_name
          expect(page).to have_content variant.display_as

          open_product_modal product
          modal_should_be_open_for product
        end

        describe "changing order cycle" do
          it "shows the correct fees after selecting and changing an order cycle" do
            enterprise_fee = create(:enterprise_fee, amount: 1001)
            exchange2.enterprise_fees << enterprise_fee
            add_variant_to_order_cycle(exchange2, variant)
            add_variant_to_order_cycle(exchange1, variant)

            # -- Selecting an order cycle
            visit shop_path
            select "turtles", from: "order_cycle_id"
            expect(page).to have_content with_currency(1020.99)

            # -- Cart shows correct price
            click_add_to_cart variant
            expect(page).to have_in_cart with_currency(1020.99)
            toggle_cart

            # -- Changing order cycle
            accept_alert do
              select "frogs", from: "order_cycle_id"
            end
            expect(page).to have_content with_currency(19.99)

            # -- Cart should be cleared
            # ng-animate means that the old product row is likely to be present, so we ensure
            # that we are not filling in the quantity on the outgoing row
            expect(page).not_to have_selector "tr.product-cart"
            within('product:not(.ng-leave)') { click_add_to_cart variant }
            expect(page).to have_in_cart with_currency(19.99)
          end

          describe "declining to clear the cart" do
            before do
              add_variant_to_order_cycle(exchange2, variant)
              add_variant_to_order_cycle(exchange1, variant)

              visit shop_path
              select "turtles", from: "order_cycle_id"
              click_add_to_cart variant
            end

            it "leaves the cart untouched when the user declines" do
              handle_js_confirm(false) do
                select "frogs", from: "order_cycle_id"
                expect(page).to have_in_cart "1"
                expect(page).to have_selector "tr.product-cart"

                # The order cycle choice should not have changed
                expect(page).to have_select 'order_cycle_id', selected: 'turtles'
              end
            end
          end
        end

        describe "two order cycles" do
          before do
            visit shop_path
          end
          context "one having 20 products" do
            before do
              20.times do
                product = create(:simple_product, supplier: supplier)
                add_variant_to_order_cycle(exchange1, product.variants.first)
              end
            end
            it "displays 20 products, 10 per page" do
              select "frogs", from: "order_cycle_id"
              expect(page).to have_selector("product.animate-repeat", count: 10)
              scroll_to(page.find(".product-listing"), align: :bottom)
              expect(page).to have_selector("product.animate-repeat", count: 20)
            end
          end

          context "another having 5 products" do
            before do
              5.times do
                product = create(:simple_product, supplier: supplier)
                add_variant_to_order_cycle(exchange2, product.variants.first)
              end
            end

            it "displays 5 products, on one page" do
              select "turtles", from: "order_cycle_id"
              expect(page).to have_selector("product.animate-repeat", count: 5)
            end
          end
        end
      end
    end

    describe "after selecting an order cycle with products visible" do
      let(:variant1) { create(:variant, product: product, price: 20) }
      let(:variant2) { create(:variant, product: product, price: 30, display_name: "Badgers") }
      let(:product2) {
        create(:simple_product, supplier: supplier, name: "Meercats", meta_keywords: "Wild")
      }
      let(:variant3) { create(:variant, product: product2, price: 40, display_name: "Ferrets") }
      let(:exchange) { Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) }

      before do
        exchange.update_attribute :pickup_time, "frogs"
        add_variant_to_order_cycle(exchange, variant)
        add_variant_to_order_cycle(exchange, variant1)
        add_variant_to_order_cycle(exchange, variant2)
        add_variant_to_order_cycle(exchange, variant3)
        order.order_cycle = oc1
      end

      context "adjusting the price" do
        before do
          enterprise_fee1 = create(:enterprise_fee, amount: 20)
          enterprise_fee2 = create(:enterprise_fee, amount: 3)
          exchange.enterprise_fees = [enterprise_fee1, enterprise_fee2]
          exchange.save
          visit shop_path
        end
        it "displays the correct price" do
          # Page should not have product.price (with or without fee)
          expect(page).not_to have_price with_currency(10.00)
          expect(page).not_to have_price with_currency(33.00)

          # Page should have variant prices (with fee)
          expect(page).to have_price with_currency(43.00)
          expect(page).to have_price with_currency(53.00)

          # Product price should be listed as the lesser of these
          expect(page).to have_price with_currency(43.00)
        end
      end

      context "filtering search results" do
        it "returns no results and clears searches by clicking the clear-link" do
          visit shop_path
          sleep(2)
          fill_in "search", with: "74576345634XXXXXX"
          expect(page).to have_content "Sorry, no results found"
          expect(page).not_to have_content product2.name
          click_on "Clear search" # clears search by clicking text
          expect(page).to have_content("Add", count: 4)
        end
        it "returns results and clears searches by clicking the clear-button" do
          visit shop_path
          sleep(2)
          fill_in "search", with: "Meer" # For product named "Meercats"
          expect(page).to have_content product2.name
          expect(page).not_to have_content product.name
          find("a.clear").click # clears search by clicking the X button
          expect(page).to have_content("Add", count: 4)
        end
      end

      context "when supplier uses property" do
        let(:product3) { create(:simple_product, supplier: supplier, inherits_properties: false) }

        before do
          add_variant_to_order_cycle(exchange, product3.variants.first)
          property = create(:property, presentation: 'certified')
          supplier.update!(properties: [property])
        end

        it "filters product by properties" do
          visit shop_path

          expect(page).to have_content product2.name
          expect(page).to have_content product3.name

          expect(page).to have_selector ".sticky-shop-filters-container .property-selectors span", text: "certified"
          find(".sticky-shop-filters-container .property-selectors span", text: 'certified').click
          expect(page).to have_content "Results for certified"

          expect(page).to have_content product2.name
          expect(page).not_to have_content product3.name
        end
      end

      it "returns search results for products where the search term matches one of the product's variant names" do
        visit shop_path
        fill_in "search", with: "Badg" # For variant with display_name "Badgers"

        within('div.pad-top') do
          expect(page).not_to have_content product2.name
          expect(page).not_to have_content variant3.display_name
          expect(page).to have_content product.name
          expect(page).to have_content variant2.display_name
        end
      end

      context "when the distributor has no available payment/shipping methods" do
        before do
          distributor.update shipping_methods: [], payment_methods: []
        end

        # Display only shops are a very useful hack that is described in the user guide
        it "still renders a display only shop" do
          visit shop_path
          expect(page).to have_content product.name

          click_add_to_cart variant
          expect(page).to have_in_cart product.name

          # Try to go to cart
          visit main_app.cart_path
          expect(page).to have_content "The hub you have selected is temporarily closed for orders. Please try again later."
        end
      end
    end

    describe "group buy products" do
      let(:exchange) { Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) }
      let(:product) { create(:simple_product, group_buy: true, on_hand: 15) }
      let(:variant) { product.variants.first }
      let(:product2) { create(:simple_product, group_buy: false) }

      describe "with variants on the product" do
        let(:variant) { create(:variant, product: product, on_hand: 10 ) }
        before do
          add_variant_to_order_cycle(exchange, variant)
          set_order_cycle(order, oc1)
          set_order(order)
          visit shop_path
        end

        it "should save group buy data to the cart and display it on shopfront reload" do
          # -- Quantity
          click_add_bulk_to_cart variant, 6
          close_modal
          expect(page).to have_in_cart product.name
          toggle_cart

          expect(order.reload.line_items.first.quantity).to eq(6)

          # -- Max quantity
          open_bulk_quantity_modal(variant)
          click_add_bulk_max_to_cart 1

          expect(order.reload.line_items.first.max_quantity).to eq(7)

          # -- Reload
          visit shop_path
          within_variant(variant) do
            expect(page).to have_selector "button.bulk-buy:nth-of-type(1)", text: "6"
            expect(page).to have_selector "button.bulk-buy:nth-last-of-type(1)", text: "7"
          end
        end
      end
    end

    describe "adding and removing products from cart" do
      let(:exchange) { Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) }
      let(:product) { create(:simple_product) }
      let(:variant) { create(:variant, product: product) }
      let(:variant2) { create(:variant, product: product) }

      before do
        add_variant_to_order_cycle(exchange, variant)
        add_variant_to_order_cycle(exchange, variant2)
        set_order_cycle(order, oc1)
        visit shop_path
      end

      it "lets us add and remove products from our cart" do
        click_add_to_cart variant
        expect(page).to have_in_cart product.name
        li = Spree::Order.order(:created_at).last.line_items.order(:created_at).last
        expect(li.quantity).to eq(1)

        toggle_cart
        click_remove_from_cart variant
        toggle_cart
        within('.cart-sidebar') { expect(page).not_to have_content product.name }

        expect(Spree::LineItem.where(id: li)).to be_empty
      end

      it "lets us add a quantity greater than on_hand value if product is on_demand" do
        variant.update on_hand: 5, on_demand: true
        visit shop_path

        click_add_to_cart variant, 10

        within_variant(variant) do
          expect(page).to have_content "10 in cart"
        end
      end

      it "shows quantity of remaining stock for products with quantity less < 3 when product_stock_display is true" do
        distributor.set_preference(:product_low_stock_display, true)
        variant.update on_hand: 2
        visit shop_path

        within_variant(variant) do
          expect(page).to have_content "Only 2 left"
        end
      end

      it "alerts us when we enter a quantity greater than the stock available" do
        variant.update on_hand: 5
        visit shop_path

        click_add_to_cart variant, 5

        within_variant(variant) do
          expect(page).to have_content "5 in cart"
          expect(page).to have_button increase_quantity_symbol, disabled: true
        end
      end

      describe "when a product goes out of stock just before it's added to the cart" do
        it "stops the attempt, shows an error message and refreshes the products asynchronously" do
          expect(page).to have_content "Product"

          variant.update! on_hand: 0

          # -- Messaging
          click_add_to_cart variant

          within(".out-of-stock-modal") do
            expect(page).to have_content "stock levels for one or more of the products in your cart have reduced"
            expect(page).to have_content "#{product.name} - #{variant.unit_to_display} is now out of stock."
          end

          # -- Page updates
          # Update amount in cart
          within_variant(variant) do
            expect(page).to have_button "Add", disabled: true
            expect(page).to have_no_content "in cart"
          end
          within_variant(variant2) do
            expect(page).to have_button "Add", disabled: false
          end

          # Update amount available in product list
          #   If amount falls to zero, variant should be greyed out and input disabled
          expect(page).to have_selector "#variant-#{variant.id}.out-of-stock"
        end

        it 'does not show out of stock modal if product is on_demand' do
          expect(page).to have_content "Product"

          variant.update! on_hand: 0, on_demand: true

          click_add_to_cart variant

          expect(page).to_not have_selector '.out-of-stock-modal'
        end

        context "group buy products" do
          let(:product) { create(:simple_product, group_buy: true) }

          it "does the same" do
            # -- Place in cart so we can set max_quantity, then make out of stock
            click_add_bulk_to_cart variant
            variant.update! on_hand: 0

            # -- Messaging
            within(".reveal-modal") do
              page.all("button", text: increase_quantity_symbol).last.click
            end
            close_modal
            wait_for_cart

            within(".out-of-stock-modal") do
              expect(page).to have_content "stock levels for one or more of the products in your cart have reduced"
              expect(page).to have_content "#{product.name} - #{variant.unit_to_display} is now out of stock."
            end

            # -- Page updates
            # Update amount in cart
            within_variant(variant) do
              expect(page).to have_button "Add", disabled: true
              expect(page).to have_no_content "in cart"
            end

            # Update amount available in product list
            #   If amount falls to zero, variant should be greyed out
            expect(page).to have_selector "#variant-#{variant.id}.out-of-stock"
          end
        end

        context "when the update is for another product" do
          it "updates quantity" do
            click_add_to_cart variant, 2

            variant.update! on_hand: 1

            click_add_to_cart variant2

            within(".out-of-stock-modal") do
              expect(page).to have_content "stock levels for one or more of the products in your cart have reduced"
              expect(page).to have_content "#{product.name} - #{variant.unit_to_display} now only has 1 remaining"
            end
          end

          context "group buy products" do
            let(:product) { create(:simple_product, group_buy: true) }

            it "does not update max_quantity" do
              click_add_bulk_to_cart variant, 2
              click_add_bulk_max_to_cart 1
              close_modal

              variant.update! on_hand: 1

              click_add_bulk_to_cart variant2

              within(".out-of-stock-modal") do
                expect(page).to have_content "stock levels for one or more of the products in your cart have reduced"
                expect(page).to have_content "#{product.name} - #{variant.unit_to_display} now only has 1 remaining"
              end

              within_variant(variant) do
                expect(page).to have_selector "button.bulk-buy:nth-of-type(1)", text: "1"
                expect(page).to have_selector "button.bulk-buy:nth-last-of-type(1)", text: "3"
              end
            end
          end
        end
      end

      context "when a variant is soft-deleted" do
        describe "adding the soft-deleted variant to the cart" do
          it "handles it as if the variant has gone out of stock" do
            sleep(2)
            variant.delete

            click_add_to_cart variant

            expect_out_of_stock_behavior
          end
        end

        context "when the soft-deleted variant has an associated override" do
          describe "adding the soft-deleted variant to the cart" do
            let!(:variant_override) {
              create(:variant_override, variant: variant, hub: distributor, count_on_hand: 100)
            }

            it "handles it as if the variant has gone out of stock" do
              sleep(2)
              variant.delete

              click_add_to_cart variant

              expect_out_of_stock_behavior
            end
          end
        end
      end
    end

    context "when no order cycles are available" do
      it "tells us orders are closed" do
        visit shop_path
        expect(page).to have_content "Orders are closed"
      end

      it "shows the last order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor], orders_open_at: 17.days.ago,
                                          orders_close_at: 10.days.ago)
        visit shop_path
        expect(page).to have_content "The last cycle closed 10 days ago"
      end

      it "shows the next order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor],
                                          orders_open_at: 10.days.from_now, orders_close_at: 17.days.from_now)
        visit shop_path
        expect(page).to have_content "The next cycle opens in 10 days"
      end
    end

    context "when shopping requires a customer" do
      let(:exchange) { Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) }
      let(:product) { create(:simple_product) }
      let(:variant) { create(:variant, product: product) }
      let(:unregistered_customer) { create(:customer, user: nil, enterprise: distributor) }

      before do
        add_variant_to_order_cycle(exchange, variant)
        set_order_cycle(order, oc1)
        distributor.require_login = true
        distributor.save!
      end

      context "when not logged in" do
        it "tells us to login" do
          visit shop_path
          expect(page).to have_content "Only approved customers can access this shop."
          expect(page).to have_content "login to proceed"
          expect(page).to have_no_content product.name
          expect(page).not_to have_selector "ordercycle"
        end
      end

      context "when logged in" do
        let(:address) { create(:address, firstname: "Foo", lastname: "Bar") }
        let(:user) { create(:user, bill_address: address, ship_address: address) }

        before do
          login_as user
        end

        context "as non-customer" do
          it "tells us to contact enterprise" do
            visit shop_path
            expect(page).to have_content "Only approved customers can access this shop."
            expect(page).to have_content "please contact #{distributor.name}"
            expect(page).to have_no_content product.name
            expect(page).not_to have_selector "ordercycle"
          end
        end

        context "as customer" do
          let!(:customer) { create(:customer, user: user, enterprise: distributor) }

          it "shows just products" do
            visit shop_path
            shows_products_without_customer_warning
          end
        end

        context "as a manager" do
          let!(:role) { create(:enterprise_role, user: user, enterprise: distributor) }

          it "shows just products" do
            visit shop_path
            shows_products_without_customer_warning
          end
        end

        context "as the owner" do
          before do
            distributor.owner = user
            distributor.save!
          end

          it "shows just products" do
            visit shop_path
            shows_products_without_customer_warning
          end
        end
      end

      context "when previously unregistered customer registers" do
        let!(:returning_user) { create(:user, email: unregistered_customer.email) }

        before do
          login_as returning_user
        end

        it "shows the products without customer only message" do
          visit shop_path
          shows_products_without_customer_warning
        end
      end
    end
  end

  def shows_products_without_customer_warning
    expect(page).to have_no_content "This shop is for customers only."
    expect(page).to have_content product.name
  end

  def expect_out_of_stock_behavior
    # Shows an "out of stock" modal, with helpful user feedback
    within(".out-of-stock-modal") do
      expect(page).to have_content 'While you\'ve been shopping, the stock levels for one or more of the products in your cart have reduced. Here\'s what\'s changed:'
    end

    # Removes the item from the client-side cart and marks the variant as unavailable
    expect(page).to have_selector "#variant-#{variant.id}.out-of-stock"
    within_variant(variant) do
      expect(page).to have_button "Add", disabled: true
      expect(page).to have_no_content "in cart"
    end
  end
end
