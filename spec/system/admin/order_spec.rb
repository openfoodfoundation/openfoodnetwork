# frozen_string_literal: true

require "system_helper"

RSpec.describe '
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
    create(:order_with_totals_and_distribution, user:, distributor:,
                                                order_cycle:, state: 'complete',
                                                payment_state: 'balance_due')
  end
  let(:customer) { order.customer }

  before do
    # ensure order has a payment to capture
    order.finalize!

    create :check_payment, order:, amount: order.total
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
    expect(page).to have_content 'Add Product'
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
      expect(page).not_to have_content "Customer Details"
      expect(page).not_to have_content "Order Details"
      expect(page).not_to have_content "Payments"
      expect(page).not_to have_content "Adjustments"
    end
  end

  context "when creating an order with a customer-only" do
    let!(:order) { create(:order, distributor:, order_cycle:) }
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

      click_button "Update"

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
          click_button "Update"
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

  context "When adding a product on an order with transaction fee" do
    let(:order_with_fees) { create(:completed_order_with_fees, user:, distributor:, order_cycle: ) }

    it "recalculates transaction fee and order total" do
      login_as_admin
      visit spree.edit_admin_order_path(order_with_fees)

      # Fee is $5 per item and we have two line items
      expect(page).to have_css("#order_adjustments", text: 10.00)
      expect(page).to have_css(".order-total", text: 36.00)

      expect {
        select2_select product.name, from: 'add_variant_id', search: true

        find('button.add_variant').click

        expect(page).to have_css("#order_adjustments", text: 15.00)
        expect(page).to have_css(".order-total", text: 63.99)
      }.to change { order_with_fees.payments.first.adjustment.amount }.from(10.00).to(15.00)
        .and change { order_with_fees.reload.total }.from(36.00).to(63.99)
    end
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
        expect do
          within(".modal") do
            click_on("OK")
          end
          expect(page).to have_content "Cannot add item to canceled order"
          expect(order.reload.state).to eq("canceled")
        end.to have_enqueued_mail(Spree::OrderMailer, :cancel_email)
          .and change { Spree::StockItem.pluck(:count_on_hand) }
      end

      it "and then the order is cancelled and email is not sent when unchecked" do
        expect do
          within(".modal") do
            uncheck("send_cancellation_email")
            click_on("OK")
          end
          expect(page).to have_content "Cannot add item to canceled order"
          expect(order.reload.state).to eq("canceled")
        end.to have_enqueued_mail(Spree::OrderMailer, :cancel_email).at_most(0).times
          .and change { Spree::StockItem.pluck(:count_on_hand) }
      end

      it "and the items are not restocked when the user uncheck the checkbox to restock items" do
        expect_any_instance_of(Spree::Variant).not_to receive(:move)
        expect do
          within(".modal") do
            uncheck("restock_items")
            click_on("OK")
          end
          expect(page).to have_content "Cannot add item to canceled order"
          expect(order.reload.state).to eq("canceled")
        end.to have_enqueued_mail(Spree::OrderMailer, :cancel_email)
          # Not change stock. Rspec can't combine `to` and `not_to` though.
          .and change { Spree::StockItem.pluck(:count_on_hand) }.by([])
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

    click_button 'Dismiss'

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

    item = order.line_items.first
    quantity = item.quantity
    max_quantity = quantity + item.variant.on_hand
    total = order.display_total

    within("tr.stock-item", text: order.products.first.name) do
      find("a.edit-item").click
      expect(page).to have_input(:quantity)
      fill_in(:quantity, with: max_quantity + 1)
      find("a.save-item").click
    end

    within(".modal") do
      expect(page).to have_content "Insufficient stock available"
      click_on "OK"
    end

    within("tr.stock-item", text: order.products.first.name) do
      expect(page).to have_field :quantity, with: max_quantity.to_s
    end
    expect { item.reload }.not_to change { item.quantity }
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
  context "creating a new order with a variant override", feature: :inventory do
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

      expect(page).to have_content 'Add Product'
      select2_select product.name, from: 'add_variant_id', search: true

      within("table.stock-levels") do
        expect(page).to have_selector("#stock_item_quantity")
        fill_in "stock_item_quantity", with: 50
        find("button.add_variant").click
      end

      expect(page).not_to have_selector("table.stock-levels")
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

  context 'when order is in confirmation state' do
    before do
      order.update(state: 'confirmation')
    end

    it 'checks order may proceed to payments' do
      login_as_admin
      visit spree.edit_admin_order_path(order)

      click_link "Payments"
      expect(page).to have_content "New Payment"
    end
  end

  describe "searching customers" do
    def searching_for_customers
      # opens the customer dropdown
      find(".items-placeholder").click

      find(".dropdown-input").send_keys("John")
      within(".customer-details") do
        expect(page).to have_content("John Doe")
        expect(page).to have_content(customer.email.to_s)
      end

      # sets the query email
      find(".dropdown-input").send_keys("maura@smith.biz")
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
        searching_for_customers
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
        searching_for_customers
      end
    end
  end
end
