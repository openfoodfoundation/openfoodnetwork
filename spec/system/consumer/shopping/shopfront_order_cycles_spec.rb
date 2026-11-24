# frozen_string_literal: true

require 'system_helper'

RSpec.describe "As a consumer I want to shop with a distributor" do
  include AuthenticationHelper
  include FileHelper
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  describe "Viewing a distributor" do
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

    before do
      pick_order order
    end

    context "when no order cycles are available" do
      it "tells us orders are closed" do
        visit shop_path
        expect(page).to have_content "Orders are closed"
      end

      it "shows the last order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor],
                                          orders_open_at: 17.days.ago,
                                          orders_close_at: 10.days.ago)
        visit shop_path
        expect(page).to have_content "The last cycle closed 10 days ago"
      end

      it "shows the next order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor],
                                          orders_open_at: 10.days.from_now,
                                          orders_close_at: 17.days.from_now)
        visit shop_path
        expect(page).to have_content "The next cycle opens in 10 days"
      end
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
          distributor.update!(preferred_shopfront_message: "Hello!")
        end

        it "shows a select with all order cycles, but doesn't show the products by default" do
          visit shop_path

          expect(page).to have_selector "option", text: 'frogs'
          expect(page).to have_selector "option", text: 'turtles'
          expect(page).to have_content "Choose when you want your order:"
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
                product = create(:simple_product, enterprise_id: supplier.id)
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
                product = create(:simple_product, enterprise_id: supplier.id)
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
      let(:variant1) { create(:variant, product:, price: 20) }
      let(:variant2) { create(:variant, product:, price: 30) }
      let(:product2) { create(:simple_product, enterprise_id: supplier.id) }
      let(:variant3) { create(:variant, product: product2, enterprise: supplier, price: 40) }
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
    end

    context "when shopping requires a customer" do
      let(:exchange) { Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) }
      let(:product) { create(:simple_product) }
      let(:variant) { create(:variant, product:) }
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
          expect(page).not_to have_content product.name
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
            expect(page).not_to have_content product.name
            expect(page).not_to have_selector "ordercycle"
          end
        end

        context "as customer" do
          let!(:customer) { create(:customer, user:, enterprise: distributor) }

          it "shows just products" do
            visit shop_path
            shows_products_without_customer_warning
          end
        end

        context "as a manager" do
          let!(:role) { create(:enterprise_role, user:, enterprise: distributor) }

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
    expect(page).not_to have_content "This shop is for customers only."
    expect(page).to have_content product.name
  end
end
