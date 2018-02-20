require 'spec_helper'

feature 'Subscriptions' do
  include AuthenticationWorkflow
  include WebHelper

  context "as an enterprise user", js: true do
    let!(:user) { create_enterprise_user(enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise, owner: user, enable_subscriptions: true) }
    let!(:shop2) { create(:distributor_enterprise, owner: user, enable_subscriptions: true) }
    let!(:shop_unmanaged) { create(:distributor_enterprise, enable_subscriptions: true) }

    before { quick_login_as user }

    context 'listing subscriptions' do
      let!(:subscription) { create(:subscription, shop: shop, with_items: true, with_proxy_orders: true) }
      let!(:subscription2) { create(:subscription, shop: shop2, with_items: true, with_proxy_orders: true) }
      let!(:subscription_unmanaged) { create(:subscription, shop: shop_unmanaged, with_items: true, with_proxy_orders: true) }

      it "passes the smoke test" do
        visit spree.admin_path
        click_link 'Orders'
        click_link 'Subscriptions'

        expect(page).to have_select2 "shop_id", with_options: [shop.name, shop2.name], without_options: [shop_unmanaged.name]

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
        fill_in 'query', with: 'blah blah blah'
        expect(page).to have_no_selector "tr#so_#{subscription.id}"
        fill_in 'query', with: ''
        expect(page).to have_selector "tr#so_#{subscription.id}"

        # Toggling columns
        expect(page).to have_selector "th.customer"
        expect(page).to have_content subscription.customer.email
        first("div#columns-dropdown", :text => "COLUMNS").click
        first("div#columns-dropdown div.menu div.menu_item", text: "Customer").click
        expect(page).to_not have_selector "th.customer"
        expect(page).to_not have_content subscription.customer.email

        # Viewing Orders
        within "tr#so_#{subscription.id}" do
          expect(page).to have_selector "td.orders.panel-toggle", text: 1
          page.find("td.orders.panel-toggle").trigger('click')
        end

        within ".subscription-orders" do
          expect(page).to have_selector "tr.proxy_order", count: 1

          proxy_order = subscription.proxy_orders.first
          within "tr#po_#{proxy_order.id}" do
            expect(page).to_not have_content 'CANCELLED'
            accept_alert 'Are you sure?' do
              find("a.cancel-order").trigger('click')
            end
            expect(page).to have_content 'CANCELLED'
            expect(proxy_order.reload.canceled_at).to be_within(5.seconds).of Time.zone.now

            # Resuming an order
            accept_alert 'Are you sure?' do
              find("a.resume-order").trigger('click')
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
    end

    context 'creating a new subscription' do
      let(:address) { create(:address) }
      let!(:customer_user) { create(:user) }
      let!(:credit_card1) { create(:credit_card, user: customer_user, cc_type: 'visa', last_digits: 1111, month: 10, year: 2030) }
      let!(:credit_card2) { create(:credit_card, user: customer_user, cc_type: 'master', last_digits: 9999, month: 2, year: 2044) }
      let!(:credit_card3) { create(:credit_card, cc_type: 'visa', last_digits: 5555, month: 6, year: 2066) }
      let!(:customer) { create(:customer, enterprise: shop, bill_address: address, user: customer_user) }
      let!(:product1) { create(:product, supplier: shop) }
      let!(:product2) { create(:product, supplier: shop) }
      let!(:variant1) { create(:variant, product: product1, unit_value: '100', price: 12.00, option_values: []) }
      let!(:variant2) { create(:variant, product: product2, unit_value: '1000', price: 6.00, option_values: []) }
      let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
      let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.days.from_now, orders_close_at: 7.days.from_now) }
      let!(:outgoing_exchange) { order_cycle.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant2], enterprise_fees: [enterprise_fee]) }
      let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
      let!(:payment_method) { create(:stripe_payment_method, name: 'Credit Card', distributors: [shop], preferred_enterprise_id: shop.id) }
      let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }

      it "passes the smoke test" do
        visit admin_subscriptions_path
        click_link 'New Subscription'
        select2_select shop.name, from: 'new_subscription_shop_id'
        click_button 'Continue'

        select2_select customer.email, from: 'customer_id'
        select2_select schedule.name, from: 'schedule_id'
        select2_select payment_method.name, from: 'payment_method_id'
        select2_select shipping_method.name, from: 'shipping_method_id'

        # Credit card
        card1_option = "Visa x-1111 #{I18n.t(:card_expiry_abbreviation)}:10/2030"
        card2_option = "Master x-9999 #{I18n.t(:card_expiry_abbreviation)}:02/2044"
        card3_option = "Visa x-5555 #{I18n.t(:card_expiry_abbreviation)}:06/2066"
        expect(page).to have_select2 'credit_card_id', with_options: [card1_option, card2_option], without_options: [card3_option]

        # No date or credit card filled out, so error returned
        click_button('Next')
        expect(page).to have_content 'can\'t be blank', count: 2
        expect(page).to have_content 'Oops! Please fill in all of the required fields...'
        fill_in 'begins_at', with: Time.zone.today.strftime('%F')
        select2_select card2_option, from: 'credit_card_id'

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
        select2_search product1.name, from: I18n.t(:name_or_sku), dropdown_css: '.select2-drop'
        fill_in 'add_quantity', with: 2
        click_link 'Add'
        within 'table#subscription-line-items tr.item', match: :first do
          expect(page).to have_selector 'td.description', text: "#{product1.name} - #{variant1.full_name}"
          expect(page).to have_selector 'td.price', text: "$13.75"
          expect(page).to have_input 'quantity', with: "2"
          expect(page).to have_selector 'td.total', text: "$27.50"
        end

        click_button('Next')

        # Deleting the existing product
        within 'table#subscription-line-items tr.item', match: :first do
          find("a.delete-item").click
        end

        # Attempting to submit without a product
        expect{
          click_button('Create Subscription')
          expect(page).to have_content 'Please add at least one product'
        }.to_not change(Subscription, :count)

        # Adding a new product
        select2_search product2.name, from: I18n.t(:name_or_sku), dropdown_css: '.select2-drop'
        fill_in 'add_quantity', with: 3
        click_link 'Add'
        within 'table#subscription-line-items tr.item', match: :first do
          expect(page).to have_selector 'td.description', text: "#{product2.name} - #{variant2.full_name}"
          expect(page).to have_selector 'td.price', text: "$7.75"
          expect(page).to have_input 'quantity', with: "3"
          expect(page).to have_selector 'td.total', text: "$23.25"
        end

        expect{
          click_button('Create Subscription')
          expect(page).to have_content 'Saved'
        }.to change(Subscription, :count).by(1)

        # Prices are shown
        within 'table#subscription-line-items tr.item', match: :first do
          expect(page).to have_selector 'td.description', text: "#{product2.name} - #{variant2.full_name}"
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
        expect(subscription.credit_card_id).to eq credit_card2.id

        # Standing Line Items are created
        expect(subscription.subscription_line_items.count).to eq 1
        subscription_line_item = subscription.subscription_line_items.first
        expect(subscription_line_item.variant).to eq variant2
        expect(subscription_line_item.quantity).to eq 3
      end

      context 'editing an existing subscription' do
        let!(:customer) { create(:customer, enterprise: shop) }
        let!(:product1) { create(:product, supplier: shop) }
        let!(:product2) { create(:product, supplier: shop) }
        let!(:product3) { create(:product, supplier: shop) }
        let!(:variant1) { create(:variant, product: product1, unit_value: '100', price: 12.00, option_values: []) }
        let!(:variant2) { create(:variant, product: product2, unit_value: '1000', price: 6.00, option_values: []) }
        let!(:variant3) { create(:variant, product: product3, unit_value: '10000', price: 22.00, option_values: []) }
        let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
        let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.days.from_now, orders_close_at: 7.days.from_now) }
        let!(:outgoing_exchange) { order_cycle.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant2], enterprise_fees: [enterprise_fee]) }
        let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
        let!(:variant3_oc) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.days.from_now, orders_close_at: 7.days.from_now) }
        let!(:variant3_ex) { variant3_oc.exchanges.create(sender: shop, receiver: shop, variants: [variant3]) }
        let!(:payment_method) { create(:payment_method, distributors: [shop]) }
        let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
        let!(:subscription) {
          create(:subscription,
                 shop: shop,
                 customer: customer,
                 schedule: schedule,
                 payment_method: payment_method,
                 shipping_method: shipping_method,
                 subscription_line_items: [create(:subscription_line_item, variant: variant1, quantity: 2)],
                 with_proxy_orders: true)
        }

        it "passes the smoke test" do
          visit edit_admin_subscription_path(subscription)

          # Customer and Schedule cannot be edited
          expect(page).to have_selector '#s2id_customer_id.select2-container-disabled'
          expect(page).to have_selector '#s2id_schedule_id.select2-container-disabled'

          # Existing products should be visible
          within "#sli_0" do
            expect(page).to have_selector 'td.description', text: "#{product1.name} - #{variant1.full_name}"
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
          select2_search product2.name, from: I18n.t(:name_or_sku), dropdown_css: '.select2-drop'
          fill_in 'add_quantity', with: 1
          click_link 'Add'
          within "#sli_0" do
            expect(page).to have_selector 'td.description', text: "#{product2.name} - #{variant2.full_name}"
            expect(page).to have_selector 'td.price', text: "$7.75"
            expect(page).to have_input 'quantity', with: "1"
            expect(page).to have_selector 'td.total', text: "$7.75"
          end

          # Total should be $7.75
          expect(page).to have_selector '#order_form_total', text: "$7.75"

          # Add variant3 to the subscription (even though it is not available)
          select2_search product3.name, from: I18n.t(:name_or_sku), dropdown_css: '.select2-drop'
          fill_in 'add_quantity', with: 1
          click_link 'Add'
          within "#sli_1" do
            expect(page).to have_selector 'td.description', text: "#{product3.name} - #{variant3.full_name}"
            expect(page).to have_selector 'td.price', text: "$22.00"
            expect(page).to have_input 'quantity', with: "1"
            expect(page).to have_selector 'td.total', text: "$22.00"
          end

          # Total should be $29.75
          expect(page).to have_selector '#order_form_total', text: "$29.75"

          click_button 'Save Changes'
          expect(page).to have_content "#{product3.name} - #{variant3.full_name} is not available from the selected schedule"

          # Remove variant3 from the subscription
          within '#sli_1' do
            find("a.delete-item").click
          end

          click_button 'Save Changes'
          expect(page).to have_content 'Saved'

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

          before { line_item.update_attributes(quantity: 3) }

          it "reports issues encountered during the update" do
            visit edit_admin_subscription_path(subscription)

            within "#sli_0" do
              fill_in 'quantity', with: "1"
            end

            click_button 'Save Changes'
            expect(page).to have_content 'Saved'

            expect(page).to have_selector "#order_update_issues_dialog .message", text: I18n.t("admin.subscriptions.order_update_issues_msg")
          end
        end
      end
    end
  end
end
