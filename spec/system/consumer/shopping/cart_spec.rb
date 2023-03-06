# frozen_string_literal: true

require 'system_helper'

describe "full-page cart" do
  include AuthenticationHelper
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  describe "viewing the cart" do
    let!(:zone) { create(:zone_with_member) }
    let(:distributor) {
      create(:distributor_enterprise, with_payment_and_shipping: true, charges_sales_tax: true)
    }
    let(:supplier) { create(:supplier_enterprise) }
    let!(:order_cycle) {
      create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                  coordinator: create(:distributor_enterprise), variants: [product_with_tax.variants.first, product_with_fee.variants.first])
    }
    let(:enterprise_fee) {
      create(:enterprise_fee, amount: 11.00, tax_category: product_with_tax.tax_category)
    }
    let(:product_with_tax) {
      create(:taxed_product, supplier: supplier, zone: zone, price: 110.00, tax_rate_amount: 0.1, included_in_price: true)
    }
    let(:product_with_fee) {
      create(:simple_product, supplier: supplier, price: 0.86, on_hand: 100)
    }
    let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor) }

    before do
      set_order order
    end

    describe "continue shopping" do
      it "shows a button leading back to the shop" do
        # Set up a shopfront message to test that we are not going to the
        # home tab.
        distributor.preferred_shopfront_message = "Test driven farming"

        add_product_to_cart order, product_with_fee, quantity: 2
        visit main_app.cart_path

        expect(page).to have_link "Continue shopping"

        click_link "Continue shopping"

        expect(page).to have_no_link "Continue shopping"
        expect(page).to have_link "Shop"
        expect(page).to have_no_content distributor.preferred_shopfront_message
      end
    end

    describe "product description" do
      it "does not link to the product page" do
        add_product_to_cart order, product_with_fee, quantity: 2
        visit main_app.cart_path
        expect(page).to have_no_selector '.item-thumb-image a'
      end
    end

    describe "when a product is soft-deleted" do
      it "shows the cart without errors" do
        add_product_to_cart order, product_with_tax, quantity: 1
        add_product_to_cart order, product_with_fee, quantity: 2
        product_with_fee.destroy

        visit main_app.cart_path
        expect(page).to have_selector '.cart-item-price'
      end
    end

    describe "percentage fees" do
      let(:percentage_fee) {
        create(:enterprise_fee,
               calculator: Calculator::FlatPercentPerItem.new(preferred_flat_percent: 20))
      }

      before do
        add_enterprise_fee percentage_fee
        add_product_to_cart order, product_with_fee, quantity: 8
        visit main_app.cart_path
      end

      it "rounds fee calculations correctly" do
        # $0.86 + 20% = $1.032
        # Fractional cents should be immediately rounded down and not carried through
        expect(page).to have_selector '.cart-item-price',         text: with_currency(1.03)
        expect(page).to have_selector '.cart-item-total',         text: with_currency(8.24)
        expect(page).to have_selector '.order-total.item-total',  text: with_currency(8.24)
        expect(page).to have_selector '.order-total.grand-total', text: with_currency(8.24)
      end
    end

    describe "admin and handling flat fees" do
      context "when there are fees" do
        let(:handling_fee) {
          create(:enterprise_fee, calculator: Calculator::FlatRate.new(preferred_amount: 1),
                                  enterprise: order_cycle.coordinator, fee_type: 'admin')
        }

        before do
          add_enterprise_fee handling_fee
          add_product_to_cart order, product_with_fee, quantity: 3
          visit main_app.cart_path
        end

        it "shows enterprise fees row row" do
          expect(page).to have_selector('#cart-detail')
          expect(page).to have_content("Whole order - #{handling_fee.name} fee by distributor #{order_cycle.coordinator.name}")
          expect(page).to have_selector '.cart-item-price',
                                        text: with_currency(0.86)
          expect(page).to have_selector '.order-total.item-total',
                                        text: with_currency(2.58)
          expect(page).to have_selector '.order-adjustment .total',
                                        text: with_currency(1.00)
          expect(page).to have_selector '.order-total.grand-total', text: with_currency(3.58) # price * 3 + 1
        end
      end

      context "when there are no admin and handling fees" do
        before do
          add_product_to_cart order, product_with_fee, quantity: 2
          visit main_app.cart_path
        end

        it "hides admin and handlings row" do
          expect(page).to have_selector('#cart-detail')
          expect(page).to have_no_content('Admin & Handling')
          expect(page).to have_selector '.cart-item-price',         text: with_currency(0.86)
          expect(page).to have_selector '.order-total.grand-total', text: with_currency(1.72) # price * 3
        end
      end
    end

    describe "admin weight calculated fees" do
      context "order with 2 line items" do
        let(:admin_fee) {
          create(:enterprise_fee, calculator: Calculator::Weight.new(preferred_per_unit: 1, preferred_unit_from_list: "kg"),
                                  enterprise: order_cycle.coordinator, fee_type: 'admin')
        }

        before do
          product_with_fee.variants.first.update(unit_value: '2000.0')
          product_with_tax.variants.first.update(unit_value: '5000.0')

          add_enterprise_fee admin_fee

          cart_service = CartService.new(order)
          cart_service.populate(variants: { product_with_fee.variants.first.id => 3,
                                            product_with_tax.variants.first.id => 3 })
          order.recreate_all_fees!

          visit main_app.cart_path
        end

        it "shows the correct weight calculations" do
          expect(page).to have_selector('#cart-detail')
          expect(page).to have_selector '.cart-item-price',                 text: with_currency(2.86) # price + (1eur * 2kg)
          expect(page).to have_selector '.cart-item-price',                 text: with_currency(115.0) # price + (1eur * 5kg)
          expect(page).to have_selector '.order-total.grand-total',         text: with_currency(353.58) # above * 3 items
        end
      end
    end

    describe "tax" do
      before do
        add_enterprise_fee enterprise_fee
        add_product_to_cart order, product_with_tax
        visit main_app.cart_path
      end

      it "shows the total tax for the order, including product tax and tax on fees" do
        expect(page).to have_selector '.tax-total', text: '11.00' # 10 + 1
      end
    end

    describe "updating quantities" do
      let(:li) { order.line_items.reload.last }
      let(:variant) { product_with_tax.variants.first }
      let(:variant2) { product_with_fee.variants.first }

      before do
        order.contents.add(product_with_tax.variants.first)
      end

      describe "when on_hand is zero but variant is on demand" do
        it "allows updating the quantity" do
          variant.update!(on_hand: 0, on_demand: true)
          visit main_app.cart_path

          fill_in "order_line_items_attributes_0_quantity", with: '5'
          expect(page).to have_field "order_line_items_attributes_0_quantity", with: '5'
        end
      end

      describe "with insufficient stock available" do
        it "prevents user from entering invalid values" do
          order.contents.add(product_with_fee.variants.first)

          variant.update!(on_hand: 2, on_demand: false)
          variant2.update!(on_hand: 3, on_demand: false)
          visit main_app.cart_path

          within "tr.variant-#{variant.id}" do
            fill_in "order_line_items_attributes_0_quantity", with: '4'
          end
          expect(page).to have_content "Insufficient stock available, only 2 remaining"
          expect(page).to have_field "order_line_items_attributes_0_quantity", with: '2'

          within "tr.variant-#{variant2.id}" do
            fill_in "order_line_items_attributes_1_quantity", with: '4'
          end
          expect(page).to have_content "Insufficient stock available, only 3 remaining"
          expect(page).to have_field "order_line_items_attributes_1_quantity", with: '3'
        end

        it "shows the quantities saved, not those submitted" do
          # Given we load the page with 3 on hand, then the number available drops to 2
          variant.update! on_demand: false
          variant.update! on_hand: 3
          visit main_app.cart_path
          variant.update! on_hand: 2

          fill_in "order_line_items_attributes_0_quantity", with: '4'
          click_button 'Update'
          expect(page).to have_field "order_line_items_attributes_0_quantity", with: '1'
        end

        describe "full UX for correcting selected quantities with insufficient stock" do
          before do
            add_product_to_cart order, product_with_tax, quantity: 5
            variant.update! on_hand: 4, on_demand: false
          end

          it "gives clear user feedback during the correcting process" do
            visit main_app.cart_path

            # shows a relevant Flash message
            expect(page).to have_selector ".alert-box",
                                          text: 'An item in your cart has become unavailable. Please update the selected quantities.'

            # "Continue Shopping" and "Checkout" buttons are disabled
            expect(page).to have_selector "a.continue-shopping[disabled=disabled]"
            expect(page).to have_selector "a#checkout-link[disabled=disabled]"

            # Quantity field clearly marked as invalid and "Update" button is not highlighted
            expect(page).to have_selector "#order_line_items_attributes_0_quantity.ng-invalid-stock"
            expect(page).to_not have_selector "#update-button.alert"

            fill_in "order_line_items_attributes_0_quantity", with: 4

            # Quantity field not marked as invalid and "Update" button is highlighted after correction
            expect(page).to_not have_selector "#order_line_items_attributes_0_quantity.ng-invalid-stock"
            expect(page).to have_selector "#update-button.alert"

            click_button 'Update'

            # "Continue Shopping" and "Checkout" buttons are not disabled after cart is updated
            expect(page).to_not have_selector "a.continue-shopping[disabled=disabled]"
            expect(page).to_not have_selector "a#checkout-link[disabled=disabled]"
          end
        end
      end
    end

    context "when ordered in the same order cycle" do
      let(:address) { create(:address) }
      let(:user) { create(:user, bill_address: address, ship_address: address) }
      let!(:prev_order1) {
        create(:completed_order_with_totals, order_cycle: order_cycle, distributor: distributor,
                                             user: user)
      }
      let!(:prev_order2) {
        create(:completed_order_with_totals, order_cycle: order_cycle, distributor: distributor,
                                             user: user)
      }

      before do
        order.user = user
        order.save
        order.distributor.allow_order_changes = true
        order.distributor.save
        add_product_to_cart order, product_with_tax
        login_as user
        visit main_app.cart_path
      end

      it "shows already ordered line items" do
        item1 = prev_order1.line_items.first
        item2 = prev_order2.line_items.first

        expect(page).to have_no_content item1.variant.name
        expect(page).to have_no_content item2.variant.name

        expect(page).to have_link 'Edit confirmed items', href: spree.account_path
        find("td.toggle-bought").click

        expect(page).to have_content item1.variant.name
        expect(page).to have_content item2.variant.name
        page.find(".line-item-#{item1.id} td.bought-item-delete a").click
        expect(page).to have_no_content item1.variant.name
        expect(page).to have_content item2.variant.name

        visit main_app.cart_path

        find("td.toggle-bought").click
        expect(page).to have_no_content item1.variant.name
        expect(page).to have_content item2.variant.name
      end

      context "with a single editable order" do # Regression test for #8191
        before do
          prev_order2.destroy
        end

        it "doesn't throw an error" do
          expect{ visit main_app.cart_path }.to_not raise_error
        end
      end
    end
  end
end
