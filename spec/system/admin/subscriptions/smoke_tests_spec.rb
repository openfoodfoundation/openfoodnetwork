# frozen_string_literal: true

require 'system_helper'

describe 'Subscriptions' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper
  include SubscriptionHelper

  context "as an enterprise user" do
    let!(:user) { create(:user) }
    let!(:shop) { create(:distributor_enterprise, owner: user, enable_subscriptions:) }
    let!(:shop2) { create(:distributor_enterprise, owner: user, enable_subscriptions:) }
    let!(:shop_unmanaged) { create(:distributor_enterprise, enable_subscriptions:) }
    let(:enable_subscriptions) { true }

    before { login_as user }

    describe "with subscriptions" do
      context "enabled" do
        before do
          visit spree.admin_dashboard_path
          click_link 'Orders'
        end
        it "the subscriptions tab is visible" do
          within "#sub_nav" do
            expect(page).to have_link "Subscriptions", href: "/admin/subscriptions"
          end

          # if conditions are not met, instructions are displayed
          click_link 'Subscriptions'
          expect(page).to have_content "Just a few more steps before you can begin"

          # subscriptions are enabled, instructions are not displayed
          expect(page).to_not have_content 'Under "Shop Preferences", /
          enable the Subscriptions option'

          # other relevant instructions are displayed
          expect(page).to have_content "Set up Shipping and Payment methods"
          expect(page).to have_content "Note that only Cash and Stripe payment methods may"
          expect(page).to have_content "be used with subscriptions"
          expect(page).to have_content "Ensure that at least one Customer exists"
          expect(page).to have_content "Create at least one Schedule"
          expect(page).to have_content "1. Go to the on the Order Cycles page"
          expect(page).to have_content "Once you are done, you can reload this page"
        end
      end
      context "disabled" do
        let(:enable_subscriptions) { false }
        before do
          visit spree.admin_dashboard_path
          click_link 'Orders'
        end
        it "the subscriptions tab is not visible" do
          expect(page).to have_current_path "/admin/orders"
          expect(page).to_not have_link "Subscriptions", href: "/admin/subscriptions"
        end
      end
    end

    describe "with an inactive order cycle" do
      let!(:customer) { create(:customer, enterprise: shop) }
      let!(:product1) { create(:product, supplier: shop) }
      let!(:product2) { create(:product, supplier: shop) }
      let!(:variant1) {
        create(:variant, product: product1, unit_value: '100', price: 12.00)
      }
      let!(:variant2) {
        create(:variant, product: product2, unit_value: '1000', price: 6.00)
      }
      let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
      let!(:order_cycle) {
        create(:simple_order_cycle,
               coordinator: shop,
               orders_open_at: 7.days.ago,
               orders_close_at: 2.days.ago)
      }
      let!(:outgoing_exchange) {
        order_cycle.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant2],
                                     enterprise_fees: [enterprise_fee])
      }
      let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
      let!(:payment_method) { create(:payment_method, distributors: [shop]) }
      let!(:stripe_payment_method) {
        create(:stripe_sca_payment_method, name: 'Credit Card', distributors: [shop])
      }
      let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
      let!(:subscription) {
        create(:subscription,
               shop:,
               customer:,
               schedule:,
               payment_method:,
               shipping_method:,
               subscription_line_items: [create(:subscription_line_item,
                                                variant: variant1,
                                                quantity: 2, price_estimate: 13.75)],
               with_proxy_orders: true)
      }

      it "that adding new subscription line item, price estimate will be nil" do
        visit edit_admin_subscription_path(subscription)
        click_button 'edit-products'

        add_variant_to_subscription(variant2, 1)

        # expect $NaN estimate price with expired oc
        within "#sli_1" do
          expect(page).to have_selector '.description',
                                        text: "#{product2.name} - #{variant2.full_name}"
          expect(page).to have_selector 'td.price', text: "$NaN"
          expect(page).to have_input 'quantity', with: "1"
        end

        expect(page).to have_selector '#order_form_total', text: "$NAN"
      end

      it "update oc to be upcoming and price estimates are not nil" do
        visit edit_admin_order_cycle_path(order_cycle)

        # update orders close
        find('#order_cycle_orders_close_at').click

        select_datetime_from_datepicker Time.zone.at(Time.zone.local(2040, 10, 24, 17, 0o0, 0o0))
        find("body").send_keys(:escape)

        click_button 'Save'

        visit edit_admin_subscription_path(subscription)
        click_button 'edit-products'

        add_variant_to_subscription(variant2, 1)

        within "#sli_1" do
          expect(page).to have_selector '.description',
                                        text: "#{product2.name} - #{variant2.full_name}"
          expect(page).to have_selector 'td.price', text: "$6.00"
          expect(page).to have_input 'quantity', with: "1"
        end

        expect(page).to have_selector '#order_form_total', text: "$33.50"
      end
    end

    describe "allowed variants" do
      let!(:customer) { create(:customer, enterprise: shop) }
      let!(:credit_card) { create(:stored_credit_card, user: customer.user) }
      let!(:shop_product) { create(:product, supplier: shop) }
      let!(:shop_product2) { create(:product, supplier: shop) }
      let!(:shop_variant) { create(:variant, product: shop_product, unit_value: "2000") }
      let!(:shop_variant2) { create(:variant, product: shop_product2, unit_value: "1000") }
      let!(:permitted_supplier) do
        create(:supplier_enterprise).tap do |supplier|
          create(:enterprise_relationship, child: shop, parent: supplier,
                                           permissions_list: [:add_to_order_cycle])
        end
      end
      let!(:permitted_supplier_product) { create(:product, supplier: permitted_supplier) }
      let!(:permitted_supplier_variant) {
        create(:variant, product: permitted_supplier_product, unit_value: "2000")
      }
      let!(:incoming_exchange_product) { create(:product) }
      let!(:incoming_exchange_variant) do
        create(:variant, product: incoming_exchange_product, unit_value: "2000").tap do |variant|
          create(:exchange, order_cycle:, incoming: true, receiver: shop,
                            variants: [variant])
        end
      end
      let!(:outgoing_exchange_product) { create(:product) }
      let!(:outgoing_exchange_variant) do
        create(:variant, product: outgoing_exchange_product, unit_value: "2000").tap do |variant|
          create(:exchange, order_cycle:, incoming: false, receiver: shop,
                            variants: [variant])
        end
      end
      let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
      let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop) }
      let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
      let!(:payment_method) { create(:stripe_sca_payment_method, distributors: [shop]) }
      let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }

      before do
        visit admin_subscriptions_path
        page.find("#new-subscription").click
        tomselect_select shop.name, from: "subscription[shop_id]"
        click_button "Continue"
      end

      it "permit creating and editing of the subscription" do
        customer.update(allow_charges: true)
        # Fill in other details
        fill_in_subscription_basic_details
        click_button "Next"
        expect(page).to have_content "BILLING ADDRESS"
        click_button "Next"

        # Add products
        expect(page).to have_content "NAME OR SKU"
        add_variant_to_subscription shop_variant, 3
        add_variant_to_subscription shop_variant2, 1
        expect_not_in_open_or_upcoming_order_cycle_warning 2
        add_variant_to_subscription permitted_supplier_variant, 4
        expect_not_in_open_or_upcoming_order_cycle_warning 3
        add_variant_to_subscription incoming_exchange_variant, 5
        expect_not_in_open_or_upcoming_order_cycle_warning 4
        add_variant_to_subscription outgoing_exchange_variant, 6
        expect_not_in_open_or_upcoming_order_cycle_warning 4
        click_button "Next"

        # Submit form
        expect {
          click_button "Create Subscription"
          expect(page).to have_current_path admin_subscriptions_path
        }.to change { Subscription.count }.by(1)

        # Subscription line items are created
        subscription = Subscription.last
        expect(subscription.subscription_line_items.count).to eq 5

        # Edit the subscription
        visit edit_admin_subscription_path(subscription)

        # Remove shop_variant from the subscription
        click_button "edit-products"
        within "#sli_0" do
          expect(page).to have_selector ".description", text: shop_variant.name
          find("a.delete-item").click
        end

        # Submit form
        click_button "Save Changes"
        expect(page).to have_current_path admin_subscriptions_path

        # Subscription is saved
        visit edit_admin_subscription_path(subscription)
        expect(page).to have_selector "#subscription-line-items .item", count: 4

        # Delete an existing product
        login_as_admin
        visit spree.admin_products_path
        within "#p_#{shop_product2.id}" do
          accept_alert { page.find("[data-powertip=Remove]").click }
        end

        visit edit_admin_subscription_path(subscription)

        # Remove deleted shop_variant from the subscription
        click_button "edit-products"
        within "#sli_0" do
          expect(page).to have_selector ".description", text: shop_variant2.name
          find("a.delete-item").click
        end
        click_button "Save Changes"
        expect(page).to have_current_path admin_subscriptions_path
        visit edit_admin_subscription_path(subscription)
        expect(page).to have_selector "#subscription-line-items .item", count: 3
      end
    end
  end
end
