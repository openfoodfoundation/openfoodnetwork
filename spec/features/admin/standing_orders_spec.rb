require 'spec_helper'

feature 'Standing Orders' do
  include AuthenticationWorkflow
  include WebHelper

  context "as an enterprise user", js: true do
    let!(:user) { create_enterprise_user(enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise, owner: user, enable_standing_orders: true) }
    let!(:shop2) { create(:distributor_enterprise, owner: user, enable_standing_orders: true) }
    let!(:shop_unmanaged) { create(:distributor_enterprise, enable_standing_orders: true) }

    before { quick_login_as user }

    context 'listing standing orders' do
      let!(:standing_order) { create(:standing_order, shop: shop, with_items: true, with_proxy_orders: true) }
      let!(:standing_order2) { create(:standing_order, shop: shop2, with_items: true, with_proxy_orders: true) }
      let!(:standing_order_unmanaged) { create(:standing_order, shop: shop_unmanaged, with_items: true, with_proxy_orders: true) }

      it "passes the smoke test" do
        visit spree.admin_path
        click_link 'Orders'
        click_link 'Standing Orders'

        expect(page).to have_select2 "shop_id", with_options: [shop.name, shop2.name], without_options: [shop_unmanaged.name]

        select2_select shop2.name, from: "shop_id"

        # Loads the right standing orders
        expect(page).to have_selector "tr#so_#{standing_order2.id}"
        expect(page).to have_no_selector "tr#so_#{standing_order.id}"
        expect(page).to have_no_selector "tr#so_#{standing_order_unmanaged.id}"
        within "tr#so_#{standing_order2.id}" do
          expect(page).to have_selector "td.customer", text: standing_order2.customer.email
        end

        # Changing Shops
        select2_select shop.name, from: "shop_id"

        # Loads the right standing orders
        expect(page).to have_selector "tr#so_#{standing_order.id}"
        expect(page).to have_no_selector "tr#so_#{standing_order2.id}"
        expect(page).to have_no_selector "tr#so_#{standing_order_unmanaged.id}"
        within "tr#so_#{standing_order.id}" do
          expect(page).to have_selector "td.customer", text: standing_order.customer.email
        end

        # Using the Quick Search
        expect(page).to have_selector "tr#so_#{standing_order.id}"
        fill_in 'query', with: 'blah blah blah'
        expect(page).to have_no_selector "tr#so_#{standing_order.id}"
        fill_in 'query', with: ''
        expect(page).to have_selector "tr#so_#{standing_order.id}"

        # Toggling columns
        expect(page).to have_selector "th.customer"
        expect(page).to have_content standing_order.customer.email
        first("div#columns-dropdown", :text => "COLUMNS").click
        first("div#columns-dropdown div.menu div.menu_item", text: "Customer").click
        expect(page).to_not have_selector "th.customer"
        expect(page).to_not have_content standing_order.customer.email

        # Viewing Orders
        within "tr#so_#{standing_order.id}" do
          expect(page).to have_selector "td.orders.panel-toggle", text: 1
          page.find("td.orders.panel-toggle").trigger('click')
        end

        within ".standing-order-orders" do
          expect(page).to have_selector "tr.proxy_order", count: 1

          proxy_order = standing_order.proxy_orders.first
          within "tr#po_#{proxy_order.id}" do
            expect(page).to_not have_content 'CANCELLED'
            accept_alert 'Are you sure?' do
              find("a.cancel-order").trigger('click')
            end
            expect(page).to have_content 'CANCELLED'
            expect(proxy_order.reload.canceled_at).to be_within(5.seconds).of Time.now

            # Resuming an order
            accept_alert 'Are you sure?' do
              find("a.resume-order").trigger('click')
            end
            # Note: the order itself was not complete when 'cancelled', so state remained as cart
            expect(page).to have_content 'PENDING'
            expect(proxy_order.reload.canceled_at).to be nil
          end
        end

        # Pausing a standing order
        within "tr#so_#{standing_order.id}" do
          find("a.pause-standing-order").click
        end
        click_button "Yes, I'm sure"
        within "tr#so_#{standing_order.id}" do
          expect(page).to have_selector ".state.paused", text: "PAUSED"
          expect(standing_order.reload.paused_at).to be_within(5.seconds).of Time.zone.now
        end

        # Unpausing a standing order
        within "tr#so_#{standing_order.id}" do
          find("a.unpause-standing-order").click
        end
        click_button "Yes, I'm sure"
        within "tr#so_#{standing_order.id}" do
          expect(page).to have_selector ".state.active", text: "ACTIVE"
          expect(standing_order.reload.paused_at).to be nil
        end

        # Cancelling a standing order
        within "tr#so_#{standing_order.id}" do
          find("a.cancel-standing-order").click
        end
        click_button "Yes, I'm sure"
        within "tr#so_#{standing_order.id}" do
          expect(page).to have_selector ".state.canceled", text: "CANCELLED"
          expect(standing_order.reload.canceled_at).to be_within(5.seconds).of Time.zone.now
        end
      end
    end

    context 'creating a new standing order' do
      let(:address) { create(:address) }
      let!(:customer) { create(:customer, enterprise: shop, bill_address: address) }
      let!(:product1) { create(:product, supplier: shop) }
      let!(:product2) { create(:product, supplier: shop) }
      let!(:variant1) { create(:variant, product: product1, unit_value: '100', price: 12.00, option_values: []) }
      let!(:variant2) { create(:variant, product: product2, unit_value: '1000', price: 6.00, option_values: []) }
      let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
      let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.days.from_now, orders_close_at: 7.days.from_now) }
      let!(:outgoing_exchange) { order_cycle.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant2], enterprise_fees: [enterprise_fee]) }
      let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
      let!(:payment_method) { create(:payment_method, distributors: [shop]) }
      let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }

      it "passes the smoke test" do
        visit admin_standing_orders_path
        click_link 'New Standing Order'
        select2_select shop.name, from: 'new_standing_order_shop_id'
        click_button 'Continue'

        select2_select customer.email, from: 'customer_id'
        select2_select schedule.name, from: 'schedule_id'
        select2_select payment_method.name, from: 'payment_method_id'
        select2_select shipping_method.name, from: 'shipping_method_id'

        # No date filled out, so error returned
        click_button('Next')
        expect(page).to have_content 'can\'t be blank'
        expect(page).to have_content 'Oops! Please fill in all of the required fields...'
        fill_in 'begins_at', with: Date.today.strftime('%F')

        click_button('Next')
        expect(page).to have_content 'BILLING ADDRESS'
        # Customer bill address has been pre-loaded
        expect(page).to have_input "bill_address_firstname", with: address.firstname
        expect(page).to have_input "bill_address_lastname", with: address.lastname
        expect(page).to have_input "bill_address_address1", with: address.address1
        click_button('Next')
        expect(page).to have_content 'can\'t be blank', count: 7 # 7 because country is set on Spree::Address.default

        # Setting the billing address
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
        targetted_select2_search product1.name, from: '#add_variant_id', dropdown_css: '.select2-drop'
        fill_in 'add_quantity', with: 2
        click_link 'Add'
        within 'table#standing-line-items tr.item', match: :first do
          expect(page).to have_selector 'td.description', text: "#{product1.name} - #{variant1.full_name}"
          expect(page).to have_selector 'td.price', text: "$13.75"
          expect(page).to have_input 'quantity', with: "2"
          expect(page).to have_selector 'td.total', text: "$27.50"
        end

        click_button('Next')

        # Deleting the existing product
        within 'table#standing-line-items tr.item', match: :first do
          find("a.delete-item").click
        end

        # Attempting to submit without a product
        expect{
          click_button('Create Standing Order')
          expect(page).to have_content 'Please add at least one product'
        }.to_not change(StandingOrder, :count)

        # Adding a new product
        targetted_select2_search product2.name, from: '#add_variant_id', dropdown_css: '.select2-drop'
        fill_in 'add_quantity', with: 3
        click_link 'Add'
        within 'table#standing-line-items tr.item', match: :first do
          expect(page).to have_selector 'td.description', text: "#{product2.name} - #{variant2.full_name}"
          expect(page).to have_selector 'td.price', text: "$7.75"
          expect(page).to have_input 'quantity', with: "3"
          expect(page).to have_selector 'td.total', text: "$23.25"
        end

        expect{
          click_button('Create Standing Order')
          expect(page).to have_content 'Saved'
        }.to change(StandingOrder, :count).by(1)

        # Prices are shown
        within 'table#standing-line-items tr.item', match: :first do
          expect(page).to have_selector 'td.description', text: "#{product2.name} - #{variant2.full_name}"
          expect(page).to have_selector 'td.price', text: "$7.75"
          expect(page).to have_input 'quantity', with: "3"
          expect(page).to have_selector 'td.total', text: "$23.25"
        end

        # Basic properties of standing order are set
        standing_order = StandingOrder.last
        expect(standing_order.customer).to eq customer
        expect(standing_order.schedule).to eq schedule
        expect(standing_order.payment_method).to eq payment_method
        expect(standing_order.shipping_method).to eq shipping_method
        expect(standing_order.bill_address.firstname).to eq 'Freda'
        expect(standing_order.ship_address.firstname).to eq 'Freda'

        # Standing Line Items are created
        expect(standing_order.standing_line_items.count).to eq 1
        standing_line_item = standing_order.standing_line_items.first
        expect(standing_line_item.variant).to eq variant2
        expect(standing_line_item.quantity).to eq 3
      end

      context 'editing an existing standing order' do
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
        let!(:standing_order) { create(:standing_order,
          shop: shop,
          customer: customer,
          schedule: schedule,
          payment_method: payment_method,
          shipping_method: shipping_method,
          standing_line_items: [create(:standing_line_item, variant: variant1, quantity: 2)],
          with_proxy_orders: true
        ) }

        it "passes the smoke test" do
          visit edit_admin_standing_order_path(standing_order)

          # Customer and Schedule cannot be edited
          expect(page).to have_selector '#s2id_customer_id.select2-container-disabled'
          expect(page).to have_selector '#s2id_schedule_id.select2-container-disabled'

          # Existing products should be visible
          within "#sli_0" do
            expect(page).to have_selector 'td.description', text: "#{product1.name} - #{variant1.full_name}"
            expect(page).to have_selector 'td.price', text: "$13.75"
            expect(page).to have_input 'quantity', with: "2"
            expect(page).to have_selector 'td.total', text: "$27.50"

            # Remove variant1 from the standing order
            find("a.delete-item").click
          end

          # Attempting to submit without a product
          click_button 'Save Changes'
          expect(page).to have_content 'Please add at least one product'

          # Add variant2 to the standing order
          targetted_select2_search product2.name, from: '#add_variant_id', dropdown_css: '.select2-drop'
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

          # Add variant3 to the standing order (even though it is not available)
          targetted_select2_search product3.name, from: '#add_variant_id', dropdown_css: '.select2-drop'
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

          # Remove variant3 from the standing order
          within '#sli_1' do
            find("a.delete-item").click
          end

          click_button 'Save Changes'
          expect(page).to have_content 'Saved'

          # Total should be $7.75
          expect(page).to have_selector '#order_form_total', text: "$7.75"
          expect(page).to have_selector 'tr.item', count: 1
          expect(standing_order.reload.standing_line_items.length).to eq 1
          expect(standing_order.standing_line_items.first.variant).to eq variant2
        end

        context "with initialised order that has been changed" do
          let(:proxy_order) { standing_order.proxy_orders.first }
          let(:order) { proxy_order.initialise_order! }
          let(:line_item) { order.line_items.first }

          before { line_item.update_attributes(quantity: 3) }

          it "reports issues encountered during the update" do
            visit edit_admin_standing_order_path(standing_order)

            within "#sli_0" do
              fill_in 'quantity', with: "1"
            end

            click_button 'Save Changes'
            expect(page).to have_content 'Saved'

            expect(page).to have_selector "#order_update_issues_dialog .message", text: I18n.t("admin.standing_orders.order_update_issues_msg")
          end
        end
      end
    end
  end
end
