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
    let(:product) { create(:simple_product, supplier_id: supplier.id, meta_keywords: "Domestic") }
    let(:variant) { product.variants.first }
    let(:order) { create(:order, distributor:) }

    before do
      pick_order order
    end

    describe "group buy products" do
      let(:exchange) { Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) }
      let(:product) { create(:simple_product, group_buy: true, on_hand: 15) }
      let(:variant) { product.variants.first }
      let(:product2) { create(:simple_product, group_buy: false) }

      describe "with variants on the product" do
        let(:variant) { create(:variant, product:, on_hand: 10 ) }
        before do
          add_variant_to_order_cycle(exchange, variant)
          set_order_cycle(order, oc1)
          pick_order(order)
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
      let(:variant) { create(:variant, product:) }
      let(:variant2) { create(:variant, product:) }

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

      it "shows quantity of remaining stock for products with quantity less < 3 when " \
         "product_stock_display is true" do
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
            expect(page).to have_content "stock levels for one or more of the products " \
                                         "in your cart have reduced"
            expect(page).to have_content "#{product.name} - #{variant.unit_to_display} " \
                                         "is now out of stock."
          end

          # -- Page updates
          # Update amount in cart
          within_variant(variant) do
            expect(page).to have_button "Add", disabled: true
            expect(page).not_to have_content "in cart"
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

          expect(page).not_to have_selector '.out-of-stock-modal'
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
              expect(page).to have_content "stock levels for one or more of the products " \
                                           "in your cart have reduced"
              expect(page).to have_content "#{product.name} - #{variant.unit_to_display} " \
                                           "is now out of stock."
            end

            # -- Page updates
            # Update amount in cart
            within_variant(variant) do
              expect(page).to have_button "Add", disabled: true
              expect(page).not_to have_content "in cart"
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
              expect(page).to have_content("stock levels for one or more of the products " \
                                           "in your cart have reduced")
              expect(page).to have_content("#{product.name} - #{variant.unit_to_display} " \
                                           "now only has 1 remaining")
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
                expect(page).to have_content "stock levels for one or more of the products " \
                                             "in your cart have reduced"
                expect(page).to have_content "#{product.name} - #{variant.unit_to_display} " \
                                             "now only has 1 remaining"
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
              create(:variant_override, variant:, hub: distributor, count_on_hand: 100)
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

    describe "shop tabs for a distributor" do
      default_tabs = ["Shop", "About", "Producers", "Contact"].freeze
      all_tabs = (default_tabs + ["Groups", "Home"]).freeze

      before do
        visit shop_path
      end

      shared_examples_for "reveal all right tabs" do |tabs, default|
        tabs.each do |tab|
          it "shows the #{tab} tab" do
            within ".tab-buttons" do
              expect(page).to have_content tab
            end
          end
        end

        (all_tabs - tabs).each do |tab|
          it "does not show the #{tab} tab" do
            within ".tab-buttons" do
              expect(page).not_to have_content tab
            end
          end
        end

        it "shows the #{default} tab by default" do
          within ".tab-buttons" do
            expect(page).to have_selector ".selected", text: default
          end
        end
      end

      context "default" do
        it_behaves_like "reveal all right tabs", default_tabs, "Shop"
      end

      context "when the distributor has a shopfront message" do
        before do
          distributor.update_attribute(:preferred_shopfront_message, "Hello")
          visit shop_path
        end

        it_behaves_like "reveal all right tabs", default_tabs + ["Home"], "Home"
      end

      context "when the distributor has a custom tab" do
        let(:custom_tab) { create(:custom_tab, title: "Custom") }

        before do
          distributor.update(custom_tab:)
          visit shop_path
        end

        it_behaves_like "reveal all right tabs", default_tabs + ["Custom"], "Shop"
      end
    end

    describe "producers tab" do
      before do
        exchange = Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id)
        add_variant_to_order_cycle(exchange, variant)
        visit shop_path
        within ".tab-buttons" do
          click_link "Producers"
        end
      end

      it "shows the producers for a distributor" do
        expect(page).to have_content supplier.name
        find("a", text: supplier.name).click
        within ".reveal-modal" do
          expect(page).to have_content supplier.name
        end
      end

      context "when the producer visibility is set to 'hidden'" do
        before do
          supplier.visible = "hidden"
          supplier.save
          visit shop_path
          within ".tab-buttons" do
            click_link "Producers"
          end
        end

        it "shows the producer name" do
          expect(page).to have_content supplier.name
        end

        it "does not show the producer modal" do
          expect(page).not_to have_link supplier.name
          expect(page).not_to have_selector ".reveal-modal"
        end
      end
    end
  end

  def expect_out_of_stock_behavior
    # Shows an "out of stock" modal, with helpful user feedback
    within(".out-of-stock-modal") do
      expect(page).to have_content 'While you\'ve been shopping, the stock levels for one or ' \
                                   'more of the products in your cart have reduced. Here\'s ' \
                                   'what\'s changed:'
    end

    # Removes the item from the client-side cart and marks the variant as unavailable
    expect(page).to have_selector "#variant-#{variant.id}.out-of-stock"
    within_variant(variant) do
      expect(page).to have_button "Add", disabled: true
      expect(page).not_to have_content "in cart"
    end
  end
end
