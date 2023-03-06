# frozen_string_literal: true

require 'system_helper'

describe 'Subscriptions' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  context "as an enterprise user" do
    let!(:user) { create(:user) }
    let!(:shop) { create(:distributor_enterprise, owner: user, enable_subscriptions: true) }
    let!(:shop2) { create(:distributor_enterprise, owner: user, enable_subscriptions: true) }
    let!(:shop_unmanaged) { create(:distributor_enterprise, enable_subscriptions: true) }

    before { login_as user }

    context 'listing subscriptions' do
      let!(:subscription) {
        create(:subscription, shop: shop, with_items: true, with_proxy_orders: true)
      }
      let!(:customer) { create(:customer, first_name: "Timmy", last_name: "Test") }
      let!(:other_subscription) {
        create(:subscription, shop: shop, customer: customer, with_items: true,
                              with_proxy_orders: true)
      }
      let!(:subscription2) {
        create(:subscription, shop: shop2, with_items: true, with_proxy_orders: true)
      }
      let!(:subscription_unmanaged) {
        create(:subscription, shop: shop_unmanaged, with_items: true, with_proxy_orders: true)
      }

      before do
        subscription.update(shipping_fee_estimate: 3.5)
        subscription.subscription_line_items.each do |sli|
          sli.update(price_estimate: 5)
        end
      end

      it "passes the smoke test" do
        visit spree.admin_dashboard_path
        click_link 'Orders'
        click_link 'Subscriptions'

        expect(page).to have_select2 "shop_id", with_options: [shop.name, shop2.name],
                                                without_options: [shop_unmanaged.name]

        select2_select shop2.name, from: "shop_id"

        # Loads the right subscriptions
        expect(page).to have_selector "tr#so_#{subscription2.id}"
        expect(page).to have_no_selector "tr#so_#{subscription.id}"
        expect(page).to have_no_selector "tr#so_#{subscription_unmanaged.id}"
        within "tr#so_#{subscription2.id}" do
          expect(page).to have_selector "td.customer", text: subscription2.customer.email
        end

        # Changing Shops
        select2_select shop.name, from: "shop_id"

        # Loads the right subscriptions
        expect(page).to have_selector "tr#so_#{subscription.id}"
        expect(page).to have_no_selector "tr#so_#{subscription2.id}"
        expect(page).to have_no_selector "tr#so_#{subscription_unmanaged.id}"
        within "tr#so_#{subscription.id}" do
          expect(page).to have_selector "td.customer", text: subscription.customer.email
        end

        # Using the Quick Search
        expect(page).to have_selector "tr#so_#{subscription.id}"
        expect(page).to have_selector "tr#so_#{other_subscription.id}"

        # Using the Quick Search: no result
        fill_in 'query', with: 'blah blah blah'
        expect(page).to have_no_selector "tr#so_#{subscription.id}"
        expect(page).to have_no_selector "tr#so_#{other_subscription.id}"

        # Using the Quick Search: filter by email
        fill_in 'query', with: other_subscription.customer.email
        expect(page).to have_selector "tr#so_#{other_subscription.id}"
        expect(page).to have_no_selector "tr#so_#{subscription.id}"

        # Using the Quick Search: filter by first_name
        fill_in 'query', with: other_subscription.customer.first_name
        expect(page).to have_selector "tr#so_#{other_subscription.id}"
        expect(page).to have_no_selector "tr#so_#{subscription.id}"

        # Using the Quick Search: filter by last_name
        fill_in 'query', with: other_subscription.customer.last_name
        expect(page).to have_selector "tr#so_#{other_subscription.id}"
        expect(page).to have_no_selector "tr#so_#{subscription.id}"

        # Using the Quick Search: reset filter
        fill_in 'query', with: ''
        expect(page).to have_selector "tr#so_#{subscription.id}"
        expect(page).to have_selector "tr#so_#{other_subscription.id}"

        # Toggling columns
        expect(page).to have_selector "th.customer"
        expect(page).to have_content subscription.customer.email
        toggle_columns "Customer"
        expect(page).to have_no_selector "th.customer"
        expect(page).to have_no_content subscription.customer.email

        # Viewing Products
        open_subscription_products_panel

        within "#subscription-line-items" do
          expect(page).to have_selector "span#order_subtotal", text: "$15.00" # 3 x $5 items
          expect(page).to have_selector "span#order_fees", text: "$3.50" # $3.5 shipping
          expect(page).to have_selector "span#order_form_total", text: "$18.50" # 3 x $5 items + $3.5 shipping
        end

        # Viewing Orders
        within "tr#so_#{subscription.id}" do
          expect(page).to have_selector "td.orders.panel-toggle", text: 1
          page.find("td.orders.panel-toggle").click
        end

        within ".subscription-orders" do
          expect(page).to have_selector "tr.proxy_order", count: 1
          expect(page).to have_content "$18.50" # 3 x $5 items + $3.5 shipping

          proxy_order = subscription.proxy_orders.first
          within "tr#po_#{proxy_order.id}" do
            expect(page).to have_no_content 'CANCELLED'
            accept_alert 'Are you sure?' do
              find("a.cancel-order").click
            end
            expect(page).to have_content 'CANCELLED'
            expect(proxy_order.reload.canceled_at).to be_within(5.seconds).of Time.zone.now

            # Resuming an order
            accept_alert 'Are you sure?' do
              find("a.resume-order").click
            end
            # Note: the order itself was not complete when 'cancelled', so state remained as cart
            expect(page).to have_content 'PENDING'
            expect(proxy_order.reload.canceled_at).to be nil
          end
        end

        # Pausing a subscription
        within "tr#so_#{subscription.id}" do
          find("a.pause-subscription").click
        end
        click_button "Yes, I'm sure"
        within "tr#so_#{subscription.id}" do
          expect(page).to have_selector ".state.paused", text: "PAUSED"
          expect(subscription.reload.paused_at).to be_within(5.seconds).of Time.zone.now
        end

        # Unpausing a subscription
        within "tr#so_#{subscription.id}" do
          find("a.unpause-subscription").click
        end
        click_button "Yes, I'm sure"
        within "tr#so_#{subscription.id}" do
          expect(page).to have_selector ".state.active", text: "ACTIVE"
          expect(subscription.reload.paused_at).to be nil
        end

        # Cancelling a subscription
        within "tr#so_#{subscription.id}" do
          find("a.cancel-subscription").click
        end
        click_button "Yes, I'm sure"
        within "tr#so_#{subscription.id}" do
          expect(page).to have_selector ".state.canceled", text: "CANCELLED"
          expect(subscription.reload.canceled_at).to be_within(5.seconds).of Time.zone.now
        end
      end

      context "editing subscription products quantity" do
        it "updates quantity" do
          visit admin_subscriptions_path
          select2_select shop.name, from: "shop_id"
          open_subscription_products_panel

          within "#sli_0" do
            fill_in 'quantity', with: "5"
          end

          page.find("a.button.update").click
          expect(page).to have_content 'SAVED'
        end
      end

      def open_subscription_products_panel
        within "tr#so_#{subscription.id}" do
          expect(page).to have_selector "td.items.panel-toggle", text: 3
          page.find("td.items.panel-toggle").click
        end
      end
    end

    context 'creating a new subscription' do
      let(:address) { create(:address) }
      let!(:customer_user) { create(:user) }
      let!(:credit_card1) {
        create(:stored_credit_card, user: customer_user, cc_type: 'visa', last_digits: 1111, month: 10,
                                    year: 2030)
      }
      let!(:customer) {
        create(:customer, enterprise: shop, bill_address: address, user: customer_user,
                          allow_charges: true)
      }
      let!(:test_product) { create(:product, supplier: shop) }
      let!(:test_variant) {
        create(:variant, product: test_product, unit_value: "100", price: 12.00, option_values: [])
      }
      let!(:shop_product) { create(:product, supplier: shop) }
      let!(:shop_variant) {
        create(:variant, product: shop_product, unit_value: "1000", price: 6.00, option_values: [])
      }
      let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
      let!(:order_cycle) {
        create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.days.from_now,
                                    orders_close_at: 7.days.from_now)
      }
      let!(:outgoing_exchange) {
        order_cycle.exchanges.create(sender: shop, receiver: shop, variants: [test_variant, shop_variant],
                                     enterprise_fees: [enterprise_fee])
      }
      let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
      let!(:payment_method) {
        create(:stripe_sca_payment_method, name: 'Credit Card', distributors: [shop])
      }
      let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }

      before do
        visit admin_subscriptions_path
        page.find("#new-subscription").click
        tomselect_search_and_select shop.name, from: "subscription[shop_id]"
        click_button "Continue"
      end

      it "passes the smoke test" do
        select2_select customer.email, from: 'customer_id'
        select2_select schedule.name, from: 'schedule_id'
        select2_select payment_method.name, from: 'payment_method_id'
        select2_select shipping_method.name, from: 'shipping_method_id'

        # No date, so error returned
        click_button('Next')
        expect(page).to have_content 'can\'t be blank', count: 1
        expect(page).to have_content 'Oops! Please fill in all of the required fields...'
        find_field('begins_at').click
        choose_today_from_datepicker

        click_button('Next')
        expect(page).to have_content 'BILLING ADDRESS'
        # Customer bill address has been pre-loaded
        expect(page).to have_input "bill_address_firstname", with: address.firstname
        expect(page).to have_input "bill_address_lastname", with: address.lastname
        expect(page).to have_input "bill_address_address1", with: address.address1

        # Clear some elements of bill address
        fill_in "bill_address_firstname", with: ''
        fill_in "bill_address_lastname", with: ''
        fill_in "bill_address_address1", with: ''
        fill_in "bill_address_city", with: ''
        fill_in "bill_address_zipcode", with: ''
        fill_in "bill_address_phone", with: ''
        click_button('Next')
        expect(page).to have_content 'can\'t be blank', count: 6

        # Re-setting the billing address
        fill_in "bill_address_firstname", with: 'Freda'
        fill_in "bill_address_lastname", with: 'Figapple'
        fill_in "bill_address_address1", with: '7 Tempany Lane'
        fill_in "bill_address_city", with: 'Natte Yallock'
        fill_in "bill_address_zipcode", with: '3465'
        fill_in "bill_address_phone", with: '0400 123 456'
        select2_select "Australia", from: "bill_address_country_id"
        select2_select "Victoria", from: "bill_address_state_id"

        # Use copy button to fill in ship address
        click_link "Copy"
        expect(page).to have_input "ship_address_firstname", with: 'Freda'
        expect(page).to have_input "ship_address_lastname", with: 'Figapple'
        expect(page).to have_input "ship_address_address1", with: '7 Tempany Lane'

        click_button('Next')
        expect(page).to have_content 'NAME OR SKU'
        click_button('Next')
        expect(page).to have_content 'Please add at least one product'

        # Adding a product and getting a price estimate
        add_variant_to_subscription test_variant, 2
        within 'table#subscription-line-items tr.item', match: :first do
          expect(page).to have_selector '.description',
                                        text: "#{test_product.name} - #{test_variant.full_name}"
          expect(page).to have_selector 'td.price', text: "$13.75"
          expect(page).to have_input 'quantity', with: "2"
          expect(page).to have_selector 'td.total', text: "$27.50"
        end

        # Deleting the existing product
        within 'table#subscription-line-items tr.item', match: :first do
          find("a.delete-item").click
        end

        click_button('Next')

        # Attempting to submit without a product
        expect{
          click_button('Create Subscription')
          expect(page).to have_content 'Please add at least one product'
        }.to_not change(Subscription, :count)

        click_button('edit-products')

        # Adding a new product
        add_variant_to_subscription shop_variant, 3
        within 'table#subscription-line-items tr.item', match: :first do
          expect(page).to have_selector '.description',
                                        text: "#{shop_product.name} - #{shop_variant.full_name}"
          expect(page).to have_selector 'td.price', text: "$7.75"
          expect(page).to have_input 'quantity', with: "3"
          expect(page).to have_selector 'td.total', text: "$23.25"
        end

        click_button('Next')

        expect{
          click_button('Create Subscription')
          expect(page).to have_current_path admin_subscriptions_path
        }.to change(Subscription, :count).by(1)

        select2_select shop.name, from: "shop_id"
        expect(page).to have_selector "td.items.panel-toggle"
        first("td.items.panel-toggle").click

        # Prices are shown in the index
        within 'table#subscription-line-items tr.item', match: :first do
          expect(page).to have_selector '.description',
                                        text: "#{shop_product.name} - #{shop_variant.full_name}"
          expect(page).to have_selector 'td.price', text: "$7.75"
          expect(page).to have_input 'quantity', with: "3"
          expect(page).to have_selector 'td.total', text: "$23.25"
        end

        # Basic properties of subscription are set
        subscription = Subscription.last
        expect(subscription.customer).to eq customer
        expect(subscription.schedule).to eq schedule
        expect(subscription.payment_method).to eq payment_method
        expect(subscription.shipping_method).to eq shipping_method
        expect(subscription.bill_address.firstname).to eq 'Freda'
        expect(subscription.ship_address.firstname).to eq 'Freda'

        # Standing Line Items are created
        expect(subscription.subscription_line_items.count).to eq 1
        subscription_line_item = subscription.subscription_line_items.first
        expect(subscription_line_item.variant).to eq shop_variant
        expect(subscription_line_item.quantity).to eq 3
      end
    end

    context 'editing an existing subscription' do
      let!(:customer) { create(:customer, enterprise: shop) }
      let!(:product1) { create(:product, supplier: shop) }
      let!(:product2) { create(:product, supplier: shop) }
      let!(:product3) { create(:product, supplier: shop) }
      let!(:variant1) {
        create(:variant, product: product1, unit_value: '100', price: 12.00, option_values: [])
      }
      let!(:variant2) {
        create(:variant, product: product2, unit_value: '1000', price: 6.00, option_values: [])
      }
      let!(:variant3) {
        create(:variant, product: product3, unit_value: '10000', price: 22.00, option_values: [])
      }
      let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
      let!(:order_cycle) {
        create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.days.from_now,
                                    orders_close_at: 7.days.from_now)
      }
      let!(:outgoing_exchange) {
        order_cycle.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant2],
                                     enterprise_fees: [enterprise_fee])
      }
      let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
      let!(:variant3_oc) {
        create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.days.from_now,
                                    orders_close_at: 7.days.from_now)
      }
      let!(:variant3_ex) {
        variant3_oc.exchanges.create(sender: shop, receiver: shop, variants: [variant3])
      }
      let!(:payment_method) { create(:payment_method, distributors: [shop]) }
      let!(:stripe_payment_method) {
        create(:stripe_sca_payment_method, name: 'Credit Card', distributors: [shop])
      }
      let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
      let!(:subscription) {
        create(:subscription,
               shop: shop,
               customer: customer,
               schedule: schedule,
               payment_method: payment_method,
               shipping_method: shipping_method,
               subscription_line_items: [create(:subscription_line_item, variant: variant1,
                                                                         quantity: 2, price_estimate: 13.75)],
               with_proxy_orders: true)
      }

      it "passes the smoke test" do
        visit edit_admin_subscription_path(subscription)

        # Customer and Schedule cannot be edited
        click_button 'edit-details'
        expect(page).to have_selector '#s2id_customer_id.select2-container-disabled'
        expect(page).to have_selector '#s2id_schedule_id.select2-container-disabled'

        # Can't use a Stripe payment method because customer does not allow it
        select2_select stripe_payment_method.name, from: 'payment_method_id'
        expect(page).to have_content 'Charges are not allowed by this customer'
        click_button 'Save Changes'
        expect(page).to have_content 'Credit card charges are not allowed by this customer'
        select2_select payment_method.name, from: 'payment_method_id'
        click_button 'Review'

        # Existing products should be visible
        click_button 'edit-products'
        within "#sli_0" do
          expect(page).to have_selector '.description',
                                        text: "#{product1.name} - #{variant1.full_name}"
          expect(page).to have_selector 'td.price', text: "$13.75"
          expect(page).to have_input 'quantity', with: "2"
          expect(page).to have_selector 'td.total', text: "$27.50"

          # Remove variant1 from the subscription
          find("a.delete-item").click
        end

        # Attempting to submit without a product
        click_button 'Save Changes'
        expect(page).to have_content 'Please add at least one product'

        # Add variant2 to the subscription
        add_variant_to_subscription(variant2, 1)
        within "#sli_0" do
          expect(page).to have_selector '.description',
                                        text: "#{product2.name} - #{variant2.full_name}"
          expect(page).to have_selector 'td.price', text: "$7.75"
          expect(page).to have_input 'quantity', with: "1"
          expect(page).to have_selector 'td.total', text: "$7.75"
        end

        # Total should be $7.75
        expect(page).to have_selector '#order_form_total', text: "$7.75"

        # Add variant3 to the subscription (even though it is not available)
        add_variant_to_subscription(variant3, 1)
        within "#sli_1" do
          expect(page).to have_selector '.description',
                                        text: "#{product3.name} - #{variant3.full_name}"
          expect(page).to have_selector 'td.price', text: "$22.00"
          expect(page).to have_input 'quantity', with: "1"
          expect(page).to have_selector 'td.total', text: "$22.00"
        end

        # Total should be $29.75
        expect(page).to have_selector '#order_form_total', text: "$29.75"

        # Remove variant3 from the subscription
        within '#sli_1' do
          find("a.delete-item").click
        end

        click_button 'Save Changes'
        expect(page).to have_current_path admin_subscriptions_path

        select2_select shop.name, from: "shop_id"
        expect(page).to have_selector "td.items.panel-toggle"
        first("td.items.panel-toggle").click

        # Total should be $7.75
        expect(page).to have_selector '#order_form_total', text: "$7.75"
        expect(page).to have_selector 'tr.item', count: 1
        expect(subscription.reload.subscription_line_items.length).to eq 1
        expect(subscription.subscription_line_items.first.variant).to eq variant2
      end

      context "with initialised order that has been changed" do
        let(:proxy_order) { subscription.proxy_orders.first }
        let(:order) { proxy_order.initialise_order! }
        let(:line_item) { order.line_items.first }

        before { line_item.update(quantity: 3) }

        it "reports issues encountered during the update" do
          visit edit_admin_subscription_path(subscription)
          click_button 'edit-products'

          within "#sli_0" do
            fill_in 'quantity', with: "1"
          end

          click_button 'Save Changes'
          expect(page).to have_content 'Saved'

          expect(page).to have_selector "#order_update_issues_dialog .message",
                                        text: 'Some orders could not be automatically updated, this is most likely because they have been manually edited. Please review the issues listed below and make any adjustments to individual orders if required.'
        end
      end
    end

    describe "with an inactive order cycle" do
      let!(:customer) { create(:customer, enterprise: shop) }
      let!(:product1) { create(:product, supplier: shop) }
      let!(:product2) { create(:product, supplier: shop) }
      let!(:variant1) {
        create(:variant, product: product1, unit_value: '100', price: 12.00, option_values: [])
      }
      let!(:variant2) {
        create(:variant, product: product2, unit_value: '1000', price: 6.00, option_values: [])
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
               shop: shop,
               customer: customer,
               schedule: schedule,
               payment_method: payment_method,
               shipping_method: shipping_method,
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
          create(:exchange, order_cycle: order_cycle, incoming: true, receiver: shop,
                            variants: [variant])
        end
      end
      let!(:outgoing_exchange_product) { create(:product) }
      let!(:outgoing_exchange_variant) do
        create(:variant, product: outgoing_exchange_product, unit_value: "2000").tap do |variant|
          create(:exchange, order_cycle: order_cycle, incoming: false, receiver: shop,
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
        tomselect_search_and_select shop.name, from: "subscription[shop_id]"
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
        }.to change(Subscription, :count).by(1)

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
        login_as_admin_and_visit spree.admin_products_path
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

  def fill_in_subscription_basic_details
    select2_select customer.email, from: "customer_id"
    select2_select schedule.name, from: "schedule_id"
    select2_select payment_method.name, from: "payment_method_id"
    select2_select shipping_method.name, from: "shipping_method_id"

    find_field("begins_at").click
    choose_today_from_datepicker
  end

  def expect_not_in_open_or_upcoming_order_cycle_warning(count)
    expect(page).to have_content variant_not_in_open_or_upcoming_order_cycle_warning, count: count
  end

  def add_variant_to_subscription(variant, quantity)
    row_count = all("#subscription-line-items .item").length
    variant_name = variant.full_name.present? ? "#{variant.name} - #{variant.full_name}" : variant.name
    select2_select variant.name, from: "add_variant_id", search: true, select_text: variant_name
    fill_in "add_quantity", with: quantity
    click_link "Add"
    expect(page).to have_selector("#subscription-line-items .item", count: row_count + 1)
  end

  def variant_not_in_open_or_upcoming_order_cycle_warning
    'There are no open or upcoming order cycles for this product.'
  end
end
