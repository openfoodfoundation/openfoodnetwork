require 'spec_helper'

feature "As a consumer I want to shop with a distributor", js: true do
  include AuthenticationWorkflow
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  describe "Viewing a distributor" do

    let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let(:supplier) { create(:supplier_enterprise) }
    let(:oc1) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise), orders_close_at: 2.days.from_now) }
    let(:oc2) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise), orders_close_at: 3.days.from_now) }
    let(:product) { create(:simple_product, supplier: supplier, meta_keywords: "Domestic") }
    let(:variant) { product.variants.first }
    let(:order) { create(:order, distributor: distributor) }

    before do
      set_order order
    end

    it "shows a distributor with images" do
      # Given the distributor has a logo
      distributor.logo = File.new(Rails.root + 'app/assets/images/logo-white.png')
      distributor.save!

      # Then we should see the distributor and its logo
      visit shop_path
      page.should have_text distributor.name
      find("#tab_about a").click
      first("distributor img")['src'].should include distributor.logo.url(:thumb)
    end

    it "shows the producers for a distributor" do
      exchange = Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id)
      add_variant_to_order_cycle(exchange, variant)

      visit shop_path
      find("#tab_producers a").click
      page.should have_content supplier.name
    end

    describe "selecting an order cycle" do
      let(:exchange1) { oc1.exchanges.to_enterprises(distributor).outgoing.first }

      it "selects an order cycle if only one is open" do
        exchange1.update_attribute :pickup_time, "turtles"
        visit shop_path
        page.should have_selector "option[selected]", text: 'turtles'
      end

      describe "with multiple order cycles" do
        let(:exchange2) { oc2.exchanges.to_enterprises(distributor).outgoing.first }

        before do
          exchange1.update_attribute :pickup_time, "frogs"
          exchange2.update_attribute :pickup_time, "turtles"
        end

        it "shows a select with all order cycles, but doesn't show the products by default" do
          visit shop_path
          page.should have_selector "option", text: 'frogs'
          page.should have_selector "option", text: 'turtles'
          page.should_not have_selector("input.button.right", visible: true)
        end

        it "shows products after selecting an order cycle" do
          variant.update_attribute(:display_name, "kitten")
          variant.update_attribute(:display_as, "rabbit")
          add_variant_to_order_cycle(exchange1, variant)
          visit shop_path
          page.should_not have_content product.name
          Spree::Order.last.order_cycle.should == nil

          select "frogs", :from => "order_cycle_id"
          page.should have_selector "products"
          page.should have_content "Next order closing in 2 days"
          Spree::Order.last.order_cycle.should == oc1
          page.should have_content product.name
          page.should have_content variant.display_name
          page.should have_content variant.display_as

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
            page.should have_content with_currency(1020.99)

            # -- Cart shows correct price
            fill_in "variants[#{variant.id}]", with: 1
            show_cart
            within("li.cart") { page.should have_content with_currency(1020.99) }

            # -- Changing order cycle
            accept_alert do
              select "frogs", from: "order_cycle_id"
            end
            page.should have_content with_currency(19.99)

            # -- Cart should be cleared
            # ng-animate means that the old product row is likely to be present, so we explicitly
            # fill in the quantity in the incoming row
            page.should_not have_selector "tr.product-cart"
            within('product.ng-enter') { fill_in "variants[#{variant.id}]", with: 1 }
            within("li.cart") { page.should have_content with_currency(19.99) }
          end

          describe "declining to clear the cart" do
            before do
              add_variant_to_order_cycle(exchange2, variant)
              add_variant_to_order_cycle(exchange1, variant)

              visit shop_path
              select "turtles", from: "order_cycle_id"
              fill_in "variants[#{variant.id}]", with: 1
            end

            it "leaves the cart untouched when the user declines" do
              handle_js_confirm(false) do
                select "frogs", from: "order_cycle_id"
                show_cart
                page.should have_selector "tr.product-cart"
                page.should have_selector 'li.cart', text: '1 item'

                # The order cycle choice should not have changed
                page.should have_select 'order_cycle_id', selected: 'turtles'
              end
            end
          end
        end

        context "when logged in" do
          let!(:prev_order) { create(:completed_order_with_totals, order_cycle: oc1, distributor: distributor, user: order.user) }

          before do
            distributor.allow_order_changes = true
            distributor.save
            quick_login_as order.user
            visit shop_path
          end

          it "shows previous orders if order cycle was selected already" do
            select "frogs", from: "order_cycle_id"
            expect(page).to have_content "Next order closing in 2 days"
            visit shop_path
            find("#cart").click
            expect(page).to have_text(I18n.t("shared.menu.cart.already_ordered_products"))
          end

          it "shows previous orders after selecting an order cycle" do
            select "frogs", from: "order_cycle_id"
            expect(page).to have_content "Next order closing in 2 days"
            find("#cart").click
            expect(page).to have_text(I18n.t("shared.menu.cart.already_ordered_products"))
          end
        end
      end
    end

    describe "after selecting an order cycle with products visible" do
      let(:variant1) { create(:variant, product: product, price: 20) }
      let(:variant2) { create(:variant, product: product, price: 30, display_name: "Badgers") }
      let(:product2) { create(:simple_product, supplier: supplier, name: "Meercats", meta_keywords: "Wild") }
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

      it "uses the adjusted price" do
        enterprise_fee1 = create(:enterprise_fee, amount: 20)
        enterprise_fee2 = create(:enterprise_fee, amount:  3)
        exchange.enterprise_fees = [enterprise_fee1, enterprise_fee2]
        exchange.save
        visit shop_path

        # Page should not have product.price (with or without fee)
        page.should_not have_price with_currency(10.00)
        page.should_not have_price with_currency(33.00)

        # Page should have variant prices (with fee)
        page.should have_price with_currency(43.00)
        page.should have_price with_currency(53.00)

        # Product price should be listed as the lesser of these
        page.should have_price with_currency(43.00)
      end

      it "filters search results properly" do
        visit shop_path
        select "frogs", :from => "order_cycle_id"

        fill_in "search", with: "74576345634XXXXXX"
        page.should have_content "Sorry, no results found"
        page.should_not have_content product2.name

        fill_in "search", with: "Meer"           # For product named "Meercats"
        page.should have_content product2.name
        page.should_not have_content product.name

        fill_in "search", with: "Dome"           # For product with meta_keywords "Domestic"
        expect(page).to have_content product.name
        expect(page).not_to have_content product2.name
      end

      it "returns search results for products where the search term matches one of the product's variant names" do
        visit shop_path
        select "frogs", :from => "order_cycle_id"

        fill_in "search", with: "Badg"           # For variant with display_name "Badgers"

        within('div.pad-top') do
          page.should have_content product.name
          page.should have_content variant2.display_name
          page.should_not have_content product2.name
          page.should_not have_content variant3.display_name
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
          visit shop_path
        end

        it "should save group buy data to the cart and display it on shopfront reload" do
          # -- Quantity
          fill_in "variants[#{variant.id}]", with: 6
          page.should have_in_cart product.name
          wait_until { !cart_dirty }

          li = Spree::Order.order(:created_at).last.line_items.order(:created_at).last
          li.quantity.should == 6

          # -- Max quantity
          fill_in "variant_attributes[#{variant.id}][max_quantity]", with: 7
          wait_until { !cart_dirty }

          li = Spree::Order.order(:created_at).last.line_items.order(:created_at).last
          li.max_quantity.should == 7

          # -- Reload
          visit shop_path
          page.should have_field "variants[#{variant.id}]", with: 6
          page.should have_field "variant_attributes[#{variant.id}][max_quantity]", with: 7
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
        fill_in "variants[#{variant.id}]", with: '1'
        page.should have_in_cart product.name
        wait_until { !cart_dirty }
        li = Spree::Order.order(:created_at).last.line_items.order(:created_at).last
        li.quantity.should == 1

        fill_in "variants[#{variant.id}]", with: '0'
        within('li.cart') { page.should_not have_content product.name }
        wait_until { !cart_dirty }

        Spree::LineItem.where(id: li).should be_empty
      end

      it "alerts us when we enter a quantity greater than the stock available" do
        variant.update_attributes on_hand: 5
        visit shop_path

        accept_alert 'Insufficient stock available, only 5 remaining' do
          fill_in "variants[#{variant.id}]", with: '10'
        end

        page.should have_field "variants[#{variant.id}]", with: '5'
      end

      describe "when a product goes out of stock just before it's added to the cart" do
        it "stops the attempt, shows an error message and refreshes the products asynchronously" do
          expect(page).to have_content "Product"

          variant.update_attributes! on_hand: 0

          # -- Messaging
          expect(page).to have_input "variants[#{variant.id}]"
          fill_in "variants[#{variant.id}]", with: '1'
          wait_until { !cart_dirty }

          within(".out-of-stock-modal") do
            page.should have_content "stock levels for one or more of the products in your cart have reduced"
            page.should have_content "#{product.name} - #{variant.unit_to_display} is now out of stock."
          end

          # -- Page updates
          # Update amount in cart
          page.should have_field "variants[#{variant.id}]", with: '0', disabled: true
          page.should have_field "variants[#{variant2.id}]", with: ''

          # Update amount available in product list
          #   If amount falls to zero, variant should be greyed out and input disabled
          page.should have_selector "#variant-#{variant.id}.out-of-stock"
          page.should have_selector "#variants_#{variant.id}[ofn-on-hand='0']"
          page.should have_selector "#variants_#{variant.id}[disabled='disabled']"
        end

        context "group buy products" do
          let(:product) { create(:simple_product, group_buy: true) }

          it "does the same" do
            # -- Place in cart so we can set max_quantity, then make out of stock
            fill_in "variants[#{variant.id}]", with: '1'
            wait_until { !cart_dirty }
            variant.update_attributes! on_hand: 0

            # -- Messaging
            fill_in "variant_attributes[#{variant.id}][max_quantity]", with: '1'
            wait_until { !cart_dirty }

            within(".out-of-stock-modal") do
              page.should have_content "stock levels for one or more of the products in your cart have reduced"
              page.should have_content "#{product.name} - #{variant.unit_to_display} is now out of stock."
            end

            # -- Page updates
            # Update amount in cart
            page.should have_field "variant_attributes[#{variant.id}][max_quantity]", with: '0', disabled: true

            # Update amount available in product list
            #   If amount falls to zero, variant should be greyed out and input disabled
            page.should have_selector "#variant-#{variant.id}.out-of-stock"
            page.should have_selector "#variants_#{variant.id}_max[disabled='disabled']"
          end
        end

        context "when the update is for another product" do
          it "updates quantity" do
            fill_in "variants[#{variant.id}]", with: '2'
            wait_until { !cart_dirty }

            variant.update_attributes! on_hand: 1

            fill_in "variants[#{variant2.id}]", with: '1'
            wait_until { !cart_dirty }

            within(".out-of-stock-modal") do
              page.should have_content "stock levels for one or more of the products in your cart have reduced"
              page.should have_content "#{product.name} - #{variant.unit_to_display} now only has 1 remaining"
            end
          end

          context "group buy products" do
            let(:product) { create(:simple_product, group_buy: true) }

            it "does not update max_quantity" do
              fill_in "variants[#{variant.id}]", with: '2'
              fill_in "variant_attributes[#{variant.id}][max_quantity]", with: '3'
              wait_until { !cart_dirty }
              variant.update_attributes! on_hand: 1

              fill_in "variants[#{variant2.id}]", with: '1'
              wait_until { !cart_dirty }

              within(".out-of-stock-modal") do
                page.should have_content "stock levels for one or more of the products in your cart have reduced"
                page.should have_content "#{product.name} - #{variant.unit_to_display} now only has 1 remaining"
              end

              page.should have_field "variants[#{variant.id}]", with: '1'
              page.should have_field "variant_attributes[#{variant.id}][max_quantity]", with: '3'
            end
          end
        end
      end
    end

    context "when no order cycles are available" do
      it "tells us orders are closed" do
        visit shop_path
        page.should have_content "Orders are closed"
      end
      it "shows the last order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor], orders_open_at: 17.days.ago, orders_close_at: 10.days.ago)
        visit shop_path
        page.should have_content "The last cycle closed 10 days ago"
      end
      it "shows the next order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor], orders_open_at: 10.days.from_now, orders_close_at: 17.days.from_now)
        visit shop_path
        page.should have_content "The next cycle opens in 10 days"
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
          expect(page).to have_content "This shop is for customers only."
          expect(page).to have_content "Please login"
          expect(page).to have_no_content product.name
        end
      end

      context "when logged in" do
        let(:address) { create(:address, firstname: "Foo", lastname: "Bar") }
        let(:user) { create(:user, bill_address: address, ship_address: address) }

        before do
          quick_login_as user
        end

        context "as non-customer" do
          it "tells us to contact enterprise" do
            visit shop_path
            expect(page).to have_content "This shop is for customers only."
            expect(page).to have_content "Please contact #{distributor.name}"
            expect(page).to have_no_content product.name
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
          quick_login_as returning_user
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
end
