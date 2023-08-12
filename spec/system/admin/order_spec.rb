# frozen_string_literal: true

require "system_helper"

describe '
    As an administrator
    I want to create and edit orders
' do
  include WebHelper
  include AuthenticationHelper

  let(:user) { create(:user) }
  let(:product) { create(:simple_product) }
  let(:distributor) { create(:distributor_enterprise, owner: user, charges_sales_tax: true) }
  let(:order_cycle) do
    create(:simple_order_cycle, name: 'One', distributors: [distributor],
                                variants: [product.variants.first])
  end

  let(:order) do
    create(:order_with_totals_and_distribution, user: user, distributor: distributor,
                                                order_cycle: order_cycle, state: 'complete',
                                                payment_state: 'balance_due')
  end
  let(:customer) { order.customer }

  before do
    # ensure order has a payment to capture
    order.finalize!

    create :check_payment, order: order, amount: order.total
  end

  def new_order_with_distribution(distributor, order_cycle)
    visit spree.new_admin_order_path
    expect(page).to have_selector('#s2id_order_distributor_id')
    select2_select distributor.name, from: 'order_distributor_id'
    select2_select order_cycle.name, from: 'order_order_cycle_id'
    click_button 'Next'
  end

  it "creating an order with distributor and order cycle" do
    distributor_disabled = create(:distributor_enterprise)
    create(:simple_order_cycle, name: 'Two')

    login_as_admin
    visit spree.admin_orders_path
    click_link 'New Order'

    # Distributors without an order cycle should be shown as disabled
    open_select2('#s2id_order_distributor_id')
    expect(page).to have_selector "ul.select2-results li.select2-result.select2-disabled",
                                  text: distributor_disabled.name
    close_select2

    # Order cycle selector should be disabled
    expect(page).to have_selector "#s2id_order_order_cycle_id.select2-container-disabled"

    # The distributor selector should limit the order cycle selection to those for that distributor
    select2_select distributor.name, from: 'order_distributor_id'
    expect(page).to have_select2 'order_order_cycle_id', options: ['One (open)']
    select2_select order_cycle.name, from: 'order_order_cycle_id'
    click_button 'Next'

    expect(page).not_to have_selector '.flash.error'
    expect(page).not_to have_content "Line items can't be blank"

    expect(page).to have_selector 'h1', text: 'Customer Details'

    order = Spree::Order.last
    expect(order.distributor).to eq(distributor)
    expect(order.order_cycle).to eq(order_cycle)
    expect(order.line_items.count).to be_zero

    click_link "Order Details"
    expect(page).to have_content 'ADD PRODUCT'
    select2_select product.name, from: 'add_variant_id', search: true
    find('button.add_variant').click
    # Wait for JS
    page.has_selector?("table.index tbody tr")
    expect(page).to have_selector 'td', text: product.name

    expect(order.reload.line_items.count).to be_positive
  end

  context "can't create an order without selecting a distributor nor an order cycle" do
    before do
      login_as_admin
      visit spree.admin_orders_path
      click_link 'New Order'
    end

    it 'shows error when distributor is not selected' do
      click_button 'Next'

      expect(page).to have_content "Order cycle can't be blank"
      expect(page).to have_content "Distributor can't be blank"
    end

    it 'shows error when order cycle is not selected' do
      select2_select distributor.name, from: 'order_distributor_id'
      click_button 'Next'

      expect(page).to have_content "Order cycle can't be blank"
    end

    it "doesn't show links to other steps" do
      expect(page).not_to have_content "CUSTOMER DETAILS"
      expect(page).not_to have_content "ORDER DETAILS"
      expect(page).not_to have_content "PAYMENTS"
      expect(page).not_to have_content "ADJUSTMENTS"
    end
  end

  context "when creating an order with a customer-only" do
    let!(:order) { create(:order, distributor: distributor, order_cycle: order_cycle) }
    let(:customer2) { create(:customer, enterprise: distributor) }
    let(:customer3) { create(:customer, enterprise: distributor) }

    before do
      login_as_admin
      visit spree.admin_order_customer_path(order)
    end

    it "sets the customer on the order" do
      expect(order.customer_id).to be_nil

      tomselect_search_and_select customer2.email, from: 'customer_search_override'
      check 'order_use_billing'
      click_button 'Update'
      expect(page).to have_content 'Customer Details updated'

      expect(order.reload.customer).to eq customer2
    end

    context "when changing the attached customer" do
      before do
        order.update(
          customer: customer2,
          email: customer2.email,
          ship_address: customer2.ship_address,
          bill_address: customer2.bill_address
        )
        visit spree.admin_order_customer_path(order)
      end

      it "should update the order customer (not only its details)" do
        expect(page).to have_field 'order_email', with: customer2.email
        tomselect_search_and_select customer3.email, from: 'customer_search_override'
        check 'order_use_billing'

        expect(page).to have_field 'order_email', with: customer3.email

        expect do
          click_button 'Update'
          expect(page).to have_content 'Customer Details updated'
        end.to change { order.reload.customer }.from(customer2).to(customer3)
      end
    end
  end

  it "can add a product to an existing order" do
    login_as_admin
    visit spree.edit_admin_order_path(order)

    select2_select product.name, from: 'add_variant_id', search: true
    find('button.add_variant').click
    # Wait for JS
    sleep(1)
    page.has_selector?("table.index tbody tr td")
    expect(page).to have_selector 'td', text: product.name
    expect(order.line_items.reload.map(&:product)).to include product
  end

  shared_examples_for "Cancelling the order" do
    it "shows a modal about order cancellation" do
      expect(page).to have_content "This will cancel the current order."
      expect(page).to have_checked_field "Send a cancellation email to the customer"
      expect(page).to have_checked_field "Restock Items: return all items to stock"
    end

    it "that the user can close and then nothing changes" do
      within(".modal") do
        expect do
          click_on("Cancel")
        end.not_to change { order.reload.state }
      end
    end

    context "that the user can confirm" do
      let(:shipment) { order.shipments.first }

      it "and by default an Email is sent and the items are restocked" do
        expect_any_instance_of(Spree::StockLocation).to receive(:restock).at_least(1).times
        expect do
          within(".modal") do
            click_on("OK")
          end
          expect(page).to have_content "Cannot add item to canceled order"
          expect(order.reload.state).to eq("canceled")
        end.to have_enqueued_mail(Spree::OrderMailer, :cancel_email)
      end

      it "and then the order is cancelled and email is not sent when unchecked" do
        expect_any_instance_of(Spree::StockLocation).to receive(:restock).at_least(1).times
        expect do
          within(".modal") do
            uncheck("send_cancellation_email")
            click_on("OK")
          end
          expect(page).to have_content "Cannot add item to canceled order"
          expect(order.reload.state).to eq("canceled")
        end.to_not have_enqueued_mail(Spree::OrderMailer, :cancel_email)
      end

      it "and the items are not restocked when the user uncheck the checkbox to restock items" do
        expect_any_instance_of(Spree::StockLocation).not_to receive(:restock)
        expect do
          within(".modal") do
            uncheck("restock_items")
            click_on("OK")
          end
          expect(page).to have_content "Cannot add item to canceled order"
          expect(order.reload.state).to eq("canceled")
        end.to have_enqueued_mail(Spree::OrderMailer, :cancel_email)
      end
    end
  end

  context "cancelling an order" do
    let(:line_item) { create(:line_item) }

    before do
      order.line_items << line_item
      login_as_admin
      visit spree.edit_admin_order_path(order)
    end

    context "when using the cancel button" do
      before do
        find("#cancel_order_form").click
      end

      it_should_behave_like "Cancelling the order"
    end

    context "when using the cancel option in the dropdown" do
      before do
        find("#links-dropdown .ofn-drop-down").click
        find('a[href$="cancel"]').click
      end

      it_should_behave_like "Cancelling the order"
    end
  end

  it "displays error when incorrect distribution for products is chosen" do
    d = create(:distributor_enterprise)
    oc = create(:simple_order_cycle, distributors: [d])

    # Move the order back to the cart state
    order.state = 'cart'
    order.completed_at = nil
    # A nil user keeps the order in the cart state
    #   Even if the edit page tries to automatically progress the order workflow
    order.user = nil
    order.save

    login_as_admin
    visit spree.edit_admin_order_path(order)

    expect(page).to have_select2 "order_distributor_id", with_options: [d.name]
    select2_select d.name, from: 'order_distributor_id'
    select2_select oc.name, from: 'order_order_cycle_id'

    click_button 'Update And Recalculate Fees'
    expect(page).to have_content "Distributor or order cycle " \
                                 "cannot supply the products in your cart"
  end

  it "can't add products to an order outside the order's hub and order cycle" do
    product = create(:simple_product)

    login_as_admin
    visit spree.edit_admin_order_path(order)

    expect(page).not_to have_select2 "add_variant_id", with_options: [product.name]
  end

  context "deleting item of an order" do
    context "when there a more than one items in the order" do
      let(:line_item) { create(:line_item) }

      before do
        order.line_items << line_item
        login_as_admin
        visit spree.edit_admin_order_path(order)
        find("a.delete-item").click
        expect(page).to have_content "Are you sure?"
      end

      it "show a modal 'Are you sure?' that the user can close and then nothing change" do
        within(".modal") do
          expect do
            click_on("Cancel")
            expect(page).not_to have_content "Are you sure?"
          end.not_to change { order.line_items.length }
        end
      end

      it "show a modal 'Are you sure?' that the user confirm and then the item is deleted" do
        expect(order.line_items.length).to eq(2)
        within(".modal") do
          expect do
            click_on("OK")
          end.to change { order.reload.line_items.length }.by(-1)
        end
      end
    end

    context "when it is the last item of an order" do
      before do
        # specify that order has only one line item
        order.line_items = [order.line_items.first]
        login_as_admin
        visit spree.edit_admin_order_path(order)
        find("a.delete-item").click
      end

      it_should_behave_like "Cancelling the order"
    end
  end

  it "can't add more items than are available" do
    # Move the order back to the cart state
    order.state = 'cart'
    order.completed_at = nil

    login_as_admin
    visit spree.edit_admin_order_path(order)

    quantity = order.line_items.first.quantity
    max_quantity = 0
    total = order.display_total

    within("tr.stock-item", text: order.products.first.name) do
      find("a.edit-item").click
      expect(page).to have_input(:quantity)
      max_quantity = find("input[name='quantity']")["max"].to_i
      fill_in(:quantity, with: max_quantity + 1)
      find("a.save-item").click
    end
    click_button("OK")

    expect(page).to_not have_content "Loading..."
    within("tr.stock-item", text: order.products.first.name) do
      expect(page).to have_text(max_quantity.to_s)
    end
    expect(order.reload.line_items.first.quantity).to eq(max_quantity)
  end

  it "there are infinite items available (variant is on demand)" do
    # Move the order back to the cart state
    order.state = 'cart'
    order.completed_at = nil
    order.line_items.first.variant.update_attribute(:on_demand, true)

    login_as_admin
    visit spree.edit_admin_order_path(order)

    within("tr.stock-item", text: order.products.first.name) do
      find("a.edit-item").click
      expect(page).to have_input(:quantity)
      fill_in(:quantity, with: 1000)
      find("a.save-item").click
    end

    within("tr.stock-item", text: order.products.first.name) do
      expect(page).to have_text("1000")
    end
    expect(order.reload.line_items.first.quantity).to eq(1000)
  end

  # Regression test for #7337
  context "creating a new order with a variant override" do
    let!(:override) {
      create(:variant_override, hub: distributor, variant: product.variants.first,
                                count_on_hand: 100)
    }

    before do
      product.variants.first.update(on_demand: false, on_hand: 0)

      login_as user
      new_order_with_distribution(distributor, order_cycle)
      expect(page).to have_selector 'h1', text: "Customer Details"
    end

    it "creates order and shipment successfully and allows proceeding to payment" do
      fill_in "order_email", with: "test@test.com"

      expect(page).to have_selector('#order_ship_address_attributes_firstname')
      check "order_use_billing"
      expect(page).not_to have_selector('#order_ship_address_attributes_firstname')

      fill_in "order_bill_address_attributes_firstname", with: "Clark"
      fill_in "order_bill_address_attributes_lastname", with: "Kent"
      fill_in "order_bill_address_attributes_address1", with: "Smallville"
      fill_in "order_bill_address_attributes_city", with: "Kansas"
      fill_in "order_bill_address_attributes_zipcode", with: "SP1 M11"

      select "Australia", from: "order_bill_address_attributes_country_id"
      select "Victoria", from: "order_bill_address_attributes_state_id"
      fill_in "order_bill_address_attributes_phone", with: "111 1111 1111"

      click_button "Update"

      expect(page).to have_content "Customer Details updated"
      click_link "Order Details"

      expect(page).to have_content 'Add Product'.upcase
      select2_select product.name, from: 'add_variant_id', search: true

      within("table.stock-levels") do
        expect(page).to have_selector("#stock_item_quantity")
        fill_in "stock_item_quantity", with: 50
        find("button.add_variant").click
      end

      expect(page).to_not have_selector("table.stock-levels")
      expect(page).to have_selector("table.stock-contents")

      within("tr.stock-item") do
        expect(page).to have_text("50")
      end

      order = Spree::Order.last
      expect(order.line_items.first.quantity).to eq(50)
      expect(order.shipments.count).to eq(1)

      new_customer = Customer.last
      expect(new_customer.full_name).to eq('Clark Kent')
      expect(new_customer.bill_address.address1).to eq('Smallville')
      expect(new_customer.bill_address.city).to eq('Kansas')
      expect(new_customer.bill_address.zipcode).to eq('SP1 M11')
      expect(new_customer.bill_address.phone).to eq('111 1111 1111')
      expect(new_customer.bill_address).to eq(new_customer.ship_address)

      click_button "Update And Recalculate Fees"

      click_link "Payments"

      expect(page).to have_content "New Payment"
    end
  end

  it "can't change distributor or order cycle once order has been finalized" do
    login_as_admin
    visit spree.edit_admin_order_path(order)

    expect(page).not_to have_select2 'order_distributor_id'
    expect(page).not_to have_select2 'order_order_cycle_id'

    expect(page).to have_selector 'p', text: "Distributor: #{order.distributor.name}"
    expect(page).to have_selector 'p', text: "Order cycle: #{order.order_cycle.name}"
  end

  it "filling customer details" do
    # Given a customer with an order, which includes their shipping and billing address

    # We change the 1st order's address details, this way
    #   we validate that the original details (stored in customer) are picked up in the 2nd order
    order.ship_address = create(:address, lastname: 'Ship')
    order.bill_address = create(:address, lastname: 'Bill')
    order.save!

    # We set the existing ship method to delivery, this ship method will be used in the 2nd order
    #   Otherwise order_updater.shipping_address_from_distributor will set
    #     the 2nd order address to the distributor address
    order.shipping_method.update_attribute :require_ship_address, true

    # When I create a new order
    login_as user
    new_order_with_distribution(distributor, order_cycle)

    # The customer selection partial should be visible
    expect(page).to have_selector '#select-customer'

    # And I select that customer's email address and save the order
    tomselect_search_and_select customer.email, from: 'customer_search_override'
    expect(page).to have_field "order_email", with: customer.email
    click_button 'Update'

    # Then their addresses should be associated with the order
    order = Spree::Order.last
    expect(order.ship_address.lastname).to eq customer.ship_address.lastname
    expect(order.bill_address.lastname).to eq customer.bill_address.lastname
    expect(order.ship_address.zipcode).to eq customer.ship_address.zipcode
    expect(order.bill_address.zipcode).to eq customer.bill_address.zipcode
    expect(order.ship_address.city).to eq customer.ship_address.city
    expect(order.bill_address.city).to eq customer.bill_address.city

    click_link "Order Details"

    select2_select product.name, from: 'add_variant_id', search: true
    find('button.add_variant').click
    page.has_selector? "table.index tbody tr" # Wait for JS
  end

  context "as an enterprise manager" do
    let(:coordinator1) { create(:distributor_enterprise) }
    let(:coordinator2) { create(:distributor_enterprise) }
    let!(:order_cycle1) { create(:order_cycle, coordinator: coordinator1) }
    let!(:order_cycle2) { create(:simple_order_cycle, coordinator: coordinator2) }
    let!(:supplier1) { order_cycle1.suppliers.first }
    let!(:supplier2) { order_cycle1.suppliers.last }
    let!(:distributor1) { order_cycle1.distributors.first }
    let!(:distributor2) do
      order_cycle1.distributors.reject{ |d| d == distributor1 }.last # ensure d1 != d2
    end
    let(:product) { order_cycle1.products.first }

    before(:each) do
      @enterprise_user = create(:user)
      @enterprise_user.enterprise_roles.build(enterprise: supplier1).save
      @enterprise_user.enterprise_roles.build(enterprise: coordinator1).save
      @enterprise_user.enterprise_roles.build(enterprise: distributor1).save

      login_as @enterprise_user
    end

    describe "viewing the edit page" do
      let!(:shipping_method_for_distributor1) do
        create(:shipping_method_with, :flat_rate, name: "Normal", amount: 12,
                                                  distributors: [distributor1])
      end
      let!(:order) do
        create(:order_with_taxes, distributor: distributor1, ship_address: create(:address),
                                  product_price: 110, tax_rate_amount: 0.1, included_in_price: true,
                                  tax_rate_name: "Tax 1").tap do |order|
                                    order.create_tax_charge!
                                    order.update_shipping_fees!
                                  end
      end

      before do
        distributor1.update_attribute(:abn, '12345678')

        visit spree.edit_admin_order_path(order)
      end

      it "verifying page contents" do
        # shows a list of line_items
        within('table.index tbody', match: :first) do
          order.line_items.each do |item|
            expect(page).to have_selector "td", match: :first, text: item.full_name
            expect(page).to have_selector "td.item-price", text: item.single_display_amount
            expect(page).to have_selector "input#quantity[value='#{item.quantity}']", visible: false
            expect(page).to have_selector "td.item-total", text: item.display_amount
          end
        end

        # shows the order items total
        within('fieldset#order-total') do
          expect(page).to have_selector "span.order-total", text: order.display_item_total
        end

        # shows the order non-tax adjustments
        order.adjustments.eligible.each do |adjustment|
          expect(page).to have_selector "td", match: :first, text: adjustment.label
          expect(page).to have_selector "td.total", text: adjustment.display_amount
        end

        # shows the order total
        expect(page).to have_selector "fieldset#order-total", text: order.display_total

        # shows the order tax adjustments
        within('fieldset', text: 'Line Item Adjustments'.upcase) do
          expect(page).to have_selector "td", match: :first, text: "Tax 1"
          expect(page).to have_selector "td.total", text: Spree::Money.new(10)
        end

        # shows the dropdown menu" do
        find("#links-dropdown .ofn-drop-down").click
        within "#links-dropdown" do
          expect(page).to have_link "Resend Confirmation",
                                    href: spree.resend_admin_order_path(order)
        end
      end

      context "Resending confirmation email" do
        before do
          visit spree.edit_admin_order_path(order)
          find("#links-dropdown .ofn-drop-down").click
        end

        it "shows the link" do
          expect(page).to have_link "Resend Confirmation",
                                    href: spree.resend_admin_order_path(order)
        end

        it "resends the confirmation email" do
          accept_alert "Are you sure you want to resend the order confirmation email?" do
            click_link "Resend Confirmation"
          end
          expect(page).to have_content "Order email has been resent"
        end
      end

      context "Canceling an order" do
        before do
          visit spree.edit_admin_order_path(order)
          find("#links-dropdown .ofn-drop-down").click
        end

        it "shows the link" do
          expect(page).to have_link "Cancel Order",
                                    href: spree.fire_admin_order_path(order, e: 'cancel')
        end

        it "cancels the order" do
          within ".ofn-drop-down .menu" do
            expect(page).to have_selector("span", text: "Cancel Order")
            page.find("span", text: "Cancel Order").click
          end
          within '.modal-content' do
            expect {
              find_button("OK").click
            }.to change { order.reload.state }.from('complete').to('canceled')
          end
        end
      end

      context "Check send/print invoice links" do
        shared_examples_for 'can send/print invoices' do
          before do
            visit spree.edit_admin_order_path(order)
            find("#links-dropdown .ofn-drop-down").click
          end

          it 'shows the right links' do
            expect(page).to have_link "Send Invoice", href: spree.invoice_admin_order_path(order)
            expect(page).to have_link "Print Invoice", href: spree.print_admin_order_path(order)
          end

          it 'can send invoices' do
            accept_alert "An invoice for this order will be sent to the customer. " \
                         "Are you sure you want to continue?" do
              click_link "Send Invoice"
            end
            expect(page).to have_content "Invoice email has been sent"
          end
        end

        context "when abn number is not mandatory to send/print invoices" do
          before do
            Spree::Config[:enterprise_number_required_on_invoices?] = false
            distributor1.update_attribute(:abn, "")
          end

          it_should_behave_like 'can send/print invoices'
        end

        context "when abn number is mandatory to send/print invoices" do
          before do
            Spree::Config[:enterprise_number_required_on_invoices?] = true
          end

          context "and a abn numer is set on the distributor" do
            before do
              distributor1.update_attribute(:abn, '12345678')
            end

            it_should_behave_like 'can send/print invoices'
          end

          context "and a abn number is not set on the distributor" do
            before do
              distributor1.update_attribute(:abn, "")
            end

            it "should not display links but a js alert" do
              visit spree.edit_admin_order_path(order)

              find("#links-dropdown .ofn-drop-down").click
              expect(page).to have_link "Send Invoice", href: "#"
              expect(page).to have_link "Print Invoice", href: "#"

              message = accept_prompt do
                click_link "Print Invoice"
              end
              expect(message)
                .to eq "#{distributor1.name} must have a valid ABN before invoices can be sent."

              find("#links-dropdown .ofn-drop-down").click
              message = accept_prompt do
                click_link "Send Invoice"
              end
              expect(message)
                .to eq "#{distributor1.name} must have a valid ABN before invoices can be sent."
            end
          end
        end
      end

      context "with different shipping methods" do
        let!(:different_shipping_method_for_distributor1) do
          create(:shipping_method_with, :flat_rate, name: "Different", amount: 15,
                                                    distributors: [distributor1])
        end
        let!(:shipping_method_for_distributor2) do
          create(:shipping_method, name: "Other", distributors: [distributor2])
        end

        it "can edit shipping method" do
          visit spree.edit_admin_order_path(order)

          expect(page).to_not have_content different_shipping_method_for_distributor1.name

          find('.edit-method').click
          expect(page).to have_select2('selected_shipping_rate_id',
                                       with_options: [
                                         shipping_method_for_distributor1.name,
                                         different_shipping_method_for_distributor1.name
                                       ], without_options: [shipping_method_for_distributor2.name])
          select2_select(different_shipping_method_for_distributor1.name,
                         from: 'selected_shipping_rate_id')
          find('.save-method').click

          expect(page).to have_content(
            "Shipping: #{different_shipping_method_for_distributor1.name}"
          )

          within "#order-total" do
            expect(page).to have_content "$175.00"
          end
        end

        context "when the distributor unsupport a shipping method that's selected " \
                "in an existing order " do
          before do
            distributor1.shipping_methods = [shipping_method_for_distributor1,
                                             different_shipping_method_for_distributor1]
            order.shipments.each(&:refresh_rates)
            order.shipment.adjustments.first.open
            order.select_shipping_method(different_shipping_method_for_distributor1)
            order.shipment.adjustments.first.close
            distributor1.shipping_methods = [shipping_method_for_distributor1]
          end
          context "shipment is shipped" do
            before do
              order.shipments.first.update_attribute(:state, 'shipped')
            end

            it "should not change the shipping method" do
              visit spree.edit_admin_order_path(order)
              expect(page).to have_content(
                "Shipping: #{different_shipping_method_for_distributor1.name} $15.00"
              )

              within "#order-total" do
                expect(page).to have_content "$160.00"
              end
            end

            context "when shipping rate is updated" do
              before do
                different_shipping_method_for_distributor1.shipping_rates.first.update!(cost: 16)
              end

              it "should not update the shipping cost" do
                visit spree.edit_admin_order_path(order)
                expect(page).to have_content(
                  "Shipping: #{different_shipping_method_for_distributor1.name} $15.00"
                )

                within "#order-total" do
                  expect(page).to have_content "$160.00"
                end
              end
            end
          end
          context "shipment is pending" do
            before do
              order.shipments.first.ensure_correct_adjustment
              expect(order.shipments.first.state).to eq('pending')
            end

            it "should not replace the selected shipment method" do
              visit spree.edit_admin_order_path(order)
              expect(page).to have_content(
                "Shipping: #{different_shipping_method_for_distributor1.name} $15.00"
              )

              within "#order-total" do
                expect(page).to have_content "$160.00"
              end
            end

            context "when shipping rate is updated" do
              before do
                different_shipping_method_for_distributor1.shipping_rates.first.update!(cost: 16)
              end

              it "should not update the shipping cost" do
                # Since the order is completed, the price is not supposed to be updated
                visit spree.edit_admin_order_path(order)
                expect(page).to have_content(
                  "Shipping: #{different_shipping_method_for_distributor1.name} $15.00"
                )

                within "#order-total" do
                  expect(page).to have_content "$160.00"
                end
              end
            end
          end
        end
      end

      it "can edit and delete tracking number" do
        test_tracking_number = "ABCCBA"
        expect(page).to_not have_content test_tracking_number

        find('.edit-tracking').click
        fill_in "tracking", with: test_tracking_number
        find('.save-tracking').click

        expect(page).to have_content test_tracking_number

        find('.delete-tracking.icon-trash').click
        # Cancel Deletion
        # Check if the alert box shows and after clicking cancel
        # the alert box vanishes and tracking num is still present
        expect(page).to have_content 'Are you sure?'
        find('.cancel').click
        expect(page).to_not have_content 'Are you sure?'
        expect(page).to have_content test_tracking_number

        find('.delete-tracking.icon-trash').click
        expect(page).to have_content 'Are you sure?'
        find('.confirm').click
        expect(page).to_not have_content test_tracking_number
      end

      it "can edit and delete note" do
        test_note = "this is a note"
        expect(page).to_not have_content test_note

        find('.edit-note.icon-edit').click
        fill_in "note", with: test_note
        find('.save-note').click

        expect(page).to have_content test_note

        find('.delete-note.icon-trash').click
        # Cancel Deletion
        # Check if the alert box shows and after clicking cancel
        # the alert box vanishes and note is still present
        expect(page).to have_content 'Are you sure?'
        find('.cancel').click
        expect(page).to_not have_content 'Are you sure?'
        expect(page).to have_content test_note

        find('.delete-note.icon-trash').click
        expect(page).to have_content 'Are you sure?'
        find('.confirm').click
        expect(page).to_not have_content test_note
      end

      it "viewing shipping fees" do
        shipping_fee = order.shipment_adjustments.first

        click_link "Adjustments"

        expect(page).to have_selector "tr#spree_adjustment_#{shipping_fee.id}"
        expect(page).to have_selector 'td.amount', text: shipping_fee.amount.to_s
        expect(page).to have_selector 'td.tax', text: shipping_fee.included_tax_total.to_s
      end

      context "when an included variant has been deleted" do
        let!(:deleted_variant) do
          order.line_items.first.variant.tap(&:delete)
        end

        it "still lists the variant in the order page" do
          within ".stock-contents" do
            expect(page).to have_content deleted_variant.product_and_full_name
          end
        end
      end

      context "and the order has been canceled" do
        it "does not allow modifying line items" do
          order.cancel!
          visit spree.edit_admin_order_path(order)
          within("tr.stock-item", text: order.products.first.name) do
            expect(page).to_not have_selector("a.edit-item")
          end
        end
      end

      context "when an incomplete order has some line items with insufficient stock" do
        let(:incomplete_order) do
          create(:order_with_line_items, user: user, distributor: distributor,
                                         order_cycle: order_cycle)
        end

        it "displays the out of stock line items and they can be deleted from the order" do
          incomplete_order.line_items.first.variant.update!(on_demand: false, on_hand: 0)

          visit spree.edit_admin_order_path(incomplete_order)

          expect(page).to have_content "Out of Stock".upcase

          within ".insufficient-stock-items" do
            expect(page).to have_content incomplete_order.products.first.name
            accept_alert 'Are you sure?' do
              find("a.delete-resource").click
            end
            expect(page).to_not have_content incomplete_order.products.first.name
          end

          # updates the order and verifies the warning disappears
          click_button 'Update And Recalculate Fees'
          expect(page).to_not have_content "Out of Stock".upcase
        end
      end
    end

    it "creating an order with distributor and order cycle" do
      new_order_with_distribution(distributor1, order_cycle1)
      expect(page).to have_selector 'h1', text: 'Customer Details'
      click_link "Order Details"

      expect(page).to have_content 'ADD PRODUCT'
      select2_select product.name, from: 'add_variant_id', search: true

      find('button.add_variant').click
      page.has_selector? "table.index tbody tr"
      expect(page).to have_selector 'td', text: product.name

      expect(page).to have_select2 'order_distributor_id', with_options: [distributor1.name]
      expect(page).to_not have_select2 'order_distributor_id', with_options: [distributor2.name]

      expect(page).to have_select2 'order_order_cycle_id',
                                   with_options: ["#{order_cycle1.name} (open)"]
      expect(page).to_not have_select2 'order_order_cycle_id',
                                       with_options: ["#{order_cycle2.name} (open)"]

      click_button 'Update'

      o = Spree::Order.last
      expect(o.distributor).to eq distributor1
      expect(o.order_cycle).to eq order_cycle1
    end
  end

  describe "searching customers" do
    def serching_for_customers
      # opens the customer dropdown
      find(".items-placeholder").click

      # sets the query name
      find(".dropdown-input").set("John")
      within(".customer-details") do
        expect(page).to have_content("John Doe")
        expect(page).to have_content(customer.email.to_s)
      end

      # sets the query email
      find(".dropdown-input").set("maura@smith.biz")
      within(".customer-details") do
        expect(page).to have_content("John Doe")
        expect(page).to have_content(customer.email.to_s)
      end
    end

    context "as the enterprise owner" do
      before do
        product.variants.first.update(on_demand: false, on_hand: 0)

        login_as user
        new_order_with_distribution(distributor, order_cycle)
        expect(page).to have_selector 'h1', text: "Customer Details"
      end

      it "finds a customer by name" do
        serching_for_customers
      end
    end

    context "as superadmin" do
      before do
        product.variants.first.update(on_demand: false, on_hand: 0)

        login_as_admin
        new_order_with_distribution(distributor, order_cycle)
        expect(page).to have_selector 'h1', text: "Customer Details"
      end

      it "finds a customer by name" do
        serching_for_customers
      end
    end
  end

  describe "Legal Invoices" do
    before do
      Flipper.enable(:invoices)
      login_as user
    end

    describe "for order states" do
      context "complete" do
        let!(:order1) {
          create(:order_with_totals_and_distribution, user: user, distributor:,
                                                      order_cycle: order_cycle, state: 'complete',
                                                      payment_state: 'balance_due',
                                                      customer_id: customer.id)
        }

        context "editing the order" do
          before do
            visit spree.edit_admin_order_path(order1)
          end

          it "displays the invoice tab" do
            expect(page).to have_content "Complete".upcase
            expect(page).to have_content "Invoices".upcase
          end
        end

        context "visiting the invoices tab" do
          let!(:table_header) {
            [
              "Date/Time",
              "Invoice Number",
              "Amount",
              "Status",
              "File",
            ].join(" ").upcase
          }

          let(:table_contents) {
            [
              Invoice.first.created_at.strftime('%B %d, %Y').to_s,
              "1",
              "0.0",
              "Active",
              "Download"
            ].join(" ")
          }
          let(:download_href) {
            "#{spree.print_admin_order_path(order1)}?invoice_id=#{Invoice.last.id}"
          }

          before do
            visit spree.admin_order_invoices_path(order1)
          end

          it "displays the invoices table" do
            # with no invoices, only the table header is displayed
            expect(page).to have_css "table.index"
            expect(page).to have_content "#{customer.first_name} #{customer.last_name} -"
            expect(page.find("table").text).to have_content(table_header)

            # the New invoice button should be visible
            expect(page).to have_link "Create or Update Invoice"
            click_link "Create or Update Invoice"

            # and disappear after clicking
            expect(page).to have_no_link "Create or Update Invoice"

            # creating an invoice, displays a second row
            expect(page.find("table").text).to have_content(table_contents)

            # with a valid invoice download link
            expect(page).to have_link("Download",
                                      href: download_href)
          end
        end
      end

      context "resumed" do
        let!(:order2) {
          create(:order_with_totals_and_distribution, user: user, distributor:,
                                                      order_cycle: order_cycle, state: 'resumed',
                                                      payment_state: 'balance_due')
        }
        before do
          visit spree.edit_admin_order_path(order2)
        end

        it "displays the invoice tab" do
          expect(page).to have_content "Resumed".upcase
          expect(page).to have_content "Invoices".upcase
        end
      end

      context "canceled" do
        let!(:order3) {
          create(:order_with_totals_and_distribution, user: user, distributor:,
                                                      order_cycle: order_cycle, state: 'canceled',
                                                      payment_state: 'balance_due')
        }
        before do
          visit spree.edit_admin_order_path(order3)
        end

        it "displays the invoice tab" do
          expect(page).to have_content "Cancelled".upcase
          expect(page).to have_content "Invoices".upcase
        end
      end

      context "cart" do
        let!(:order_empty) {
          create(:order_with_line_items, user: user, distributor:, order_cycle: order_cycle,
                                         line_items_count: 0)
        }
        before do
          visit spree.edit_admin_order_path(order_empty)
        end

        it "should not display the invoice tab" do
          expect(page).to have_content "Cart".upcase
          expect(page).not_to have_content "Invoices".upcase
        end
      end

      context "payment" do
        let!(:order4) do
          create(:order_ready_for_payment, user: user, distributor: distributor,
                                           order_cycle: order_cycle,
                                           payment_state: 'balance_due')
        end
        before do
          visit spree.edit_admin_order_path(order4)
        end

        it "should not display the invoice tab" do
          expect(page).to have_content "Payment".upcase
          expect(page).not_to have_content "Invoices".upcase
        end
      end
    end
  end
end
