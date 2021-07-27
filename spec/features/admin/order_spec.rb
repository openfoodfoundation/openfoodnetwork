# frozen_string_literal: true

require "spec_helper"

feature '
    As an administrator
    I want to create and edit orders
', js: true do
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

  scenario "creating an order with distributor and order cycle" do
    distributor_disabled = create(:distributor_enterprise)
    create(:simple_order_cycle, name: 'Two')

    login_as_admin_and_visit spree.admin_orders_path
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

    click_button "Update And Recalculate Fees"
    expect(page).to have_selector '.flash.error'
    expect(page).to have_content "Line items can't be blank"

    # it suppresses validation errors when setting distribution
    expect(page).not_to have_selector '#errorExplanation'
    expect(page).to have_content 'ADD PRODUCT'
    select2_select product.name, from: 'add_variant_id', search: true
    find('button.add_variant').click
    page.has_selector? "table.index tbody[data-hook='admin_order_form_line_items'] tr" # Wait for JS
    expect(page).to have_selector 'td', text: product.name

    click_button 'Update'

    expect(page).to have_selector 'h1', text: 'Customer Details'
    o = Spree::Order.last
    expect(o.distributor).to eq(distributor)
    expect(o.order_cycle).to eq(order_cycle)
  end

  scenario "can add a product to an existing order" do
    login_as_admin_and_visit spree.edit_admin_order_path(order)

    select2_select product.name, from: 'add_variant_id', search: true

    find('button.add_variant').click

    expect(page).to have_selector 'td', text: product.name
    expect(order.line_items.reload.map(&:product)).to include product
  end

  scenario "displays error when incorrect distribution for products is chosen" do
    d = create(:distributor_enterprise)
    oc = create(:simple_order_cycle, distributors: [d])

    # Move the order back to the cart state
    order.state = 'cart'
    order.completed_at = nil
    # A nil user keeps the order in the cart state
    #   Even if the edit page tries to automatically progress the order workflow
    order.user = nil
    order.save

    login_as_admin_and_visit spree.edit_admin_order_path(order)

    expect(page).to have_select2 "order_distributor_id", with_options: [d.name]
    select2_select d.name, from: 'order_distributor_id'
    select2_select oc.name, from: 'order_order_cycle_id'

    click_button 'Update And Recalculate Fees'
    expect(page).to have_content "Distributor or order cycle " \
                                 "cannot supply the products in your cart"
  end

  scenario "can't add products to an order outside the order's hub and order cycle" do
    product = create(:simple_product)

    login_as_admin_and_visit spree.edit_admin_order_path(order)

    expect(page).not_to have_select2 "add_variant_id", with_options: [product.name]
  end

  scenario "can't add more items than are available" do
    # Move the order back to the cart state
    order.state = 'cart'
    order.completed_at = nil

    login_as_admin_and_visit spree.edit_admin_order_path(order)

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
    accept_js_alert

    expect(page).to_not have_content "Loading..."
    within("tr.stock-item", text: order.products.first.name) do
      expect(page).to have_text("#{max_quantity} x")
    end
    expect(order.reload.line_items.first.quantity).to eq(max_quantity)
  end

  scenario "there are infinite items available (variant is on demand)" do
    # Move the order back to the cart state
    order.state = 'cart'
    order.completed_at = nil
    order.line_items.first.variant.update_attribute(:on_demand, true)

    login_as_admin_and_visit spree.edit_admin_order_path(order)

    within("tr.stock-item", text: order.products.first.name) do
      find("a.edit-item").click
      expect(page).to have_input(:quantity)
      fill_in(:quantity, with: 1000)
      find("a.save-item").click
    end

    within("tr.stock-item", text: order.products.first.name) do
      expect(page).to have_text("1000 x")
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
      expect(page).to have_content I18n.t('spree.add_product').upcase
    end

    it "creates order and shipment successfully and allows proceeding to payment" do
      select2_select product.name, from: 'add_variant_id', search: true

      within("table.stock-levels") do
        expect(page).to have_selector("#stock_item_quantity")
        fill_in "stock_item_quantity", with: 50
        find("button.add_variant").click
      end

      expect(page).to_not have_selector("table.stock-levels")
      expect(page).to have_selector("table.stock-contents")

      within("tr.stock-item") do
        expect(page).to have_text("50 x")
      end

      order = Spree::Order.last
      expect(order.line_items.first.quantity).to eq(50)
      expect(order.shipments.count).to eq(1)

      click_button "Update And Recalculate Fees"
      expect(page).to have_selector 'h1', text: "Customer Details"

      fill_in "order_email", with: "test@test.com"
      check "order_use_billing"
      fill_in "order_bill_address_attributes_firstname", with: "xxx"
      fill_in "order_bill_address_attributes_lastname", with: "xxx"
      fill_in "order_bill_address_attributes_address1", with: "xxx"
      fill_in "order_bill_address_attributes_city", with: "xxx"
      fill_in "order_bill_address_attributes_zipcode", with: "xxx"
      select "Australia", from: "order_bill_address_attributes_country_id"
      select "Victoria", from: "order_bill_address_attributes_state_id"
      fill_in "order_bill_address_attributes_phone", with: "xxx"

      click_button "Update"

      expect(page).to have_content "Customer Details updated"

      click_link "Payments"

      expect(page).to have_content "New Payment"
    end
  end

  scenario "can't change distributor or order cycle once order has been finalized" do
    login_as_admin_and_visit spree.edit_admin_order_path(order)

    expect(page).not_to have_select2 'order_distributor_id'
    expect(page).not_to have_select2 'order_order_cycle_id'

    expect(page).to have_selector 'p', text: "Distributor: #{order.distributor.name}"
    expect(page).to have_selector 'p', text: "Order cycle: #{order.order_cycle.name}"
  end

  scenario "filling customer details" do
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
    select2_select product.name, from: 'add_variant_id', search: true
    find('button.add_variant').click
    page.has_selector? "table.index tbody[data-hook='admin_order_form_line_items'] tr" # Wait for JS
    click_button 'Update'

    expect(page).to have_selector 'h1.js-admin-page-title', text: "Customer Details"

    # The customer selection partial should be visible
    expect(page).to have_selector '#select-customer'

    # And I select that customer's email address and save the order
    select2_select customer.email, from: 'customer_search_override', search: true
    click_button 'Update'
    expect(page).to have_selector "h1.js-admin-page-title", text: "Customer Details"

    # Then their addresses should be associated with the order
    order = Spree::Order.last
    expect(order.ship_address.lastname).to eq customer.ship_address.lastname
    expect(order.bill_address.lastname).to eq customer.bill_address.lastname
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

    feature "viewing the edit page" do
      let!(:shipping_method_for_distributor1) do
        create(:shipping_method, name: "Normal", distributors: [distributor1])
      end
      let!(:order) do
        create(:order_with_taxes, distributor: distributor1, ship_address: create(:address),
                                  product_price: 110, tax_rate_amount: 0.1,
                                  tax_rate_name: "Tax 1").tap do |order|
                                    order.create_tax_charge!
                                    order.update_shipping_fees!
                                  end
      end

      background do
        distributor1.update_attribute(:abn, '12345678')

        visit spree.edit_admin_order_path(order)
      end

      scenario "verifying page contents" do
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
        within('fieldset', text: I18n.t('spree.admin.orders.form.line_item_adjustments').upcase) do
          expect(page).to have_selector "td", match: :first, text: "Tax 1"
          expect(page).to have_selector "td.total", text: Spree::Money.new(10)
        end

        # shows the dropdown menu" do
        find("#links-dropdown .ofn-drop-down").click
        within "#links-dropdown" do
          expect(page).to have_link "Resend Confirmation",
                                    href: spree.resend_admin_order_path(order)
          expect(page).to have_link "Send Invoice", href: spree.invoice_admin_order_path(order)
          expect(page).to have_link "Print Invoice", href: spree.print_admin_order_path(order)
          expect(page).to have_link "Cancel Order",
                                    href: spree.fire_admin_order_path(order, e: 'cancel')
        end
      end

      scenario "cannot split the order in different stock locations" do
        # There's only 1 stock location in OFN,
        #   so the split functionality that comes with spree should be hidden
        expect(page).to_not have_selector '.split-item'
      end

      context "with different shipping methods" do
        let!(:different_shipping_method_for_distributor1) do
          create(:shipping_method, name: "Different", distributors: [distributor1])
        end
        let!(:shipping_method_for_distributor2) do
          create(:shipping_method, name: "Other", distributors: [distributor2])
        end

        scenario "can edit shipping method" do
          visit spree.edit_admin_order_path(order)

          expect(page).to_not have_content different_shipping_method_for_distributor1.name

          find('.edit-method').click
          expect(page).to have_select2 'selected_shipping_rate_id',
                                       with_options: [
                                         shipping_method_for_distributor1.name,
                                         different_shipping_method_for_distributor1.name
                                       ], without_options: [shipping_method_for_distributor2.name]
          select2_select different_shipping_method_for_distributor1.name,
                         from: 'selected_shipping_rate_id'
          find('.save-method').click

          expect(page).to have_content "Shipping: #{different_shipping_method_for_distributor1.name}"
        end
      end

      scenario "can edit tracking number" do
        test_tracking_number = "ABCCBA"
        expect(page).to_not have_content test_tracking_number

        find('.edit-tracking').click
        fill_in "tracking", with: test_tracking_number
        find('.save-tracking').click

        expect(page).to have_content test_tracking_number
      end

      scenario "viewing shipping fees" do
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
    end

    scenario "creating an order with distributor and order cycle" do
      new_order_with_distribution(distributor1, order_cycle1)

      expect(page).to have_content 'ADD PRODUCT'
      select2_select product.name, from: 'add_variant_id', search: true

      find('button.add_variant').click
      page.has_selector? "table.index tbody[data-hook='admin_order_form_line_items'] tr"
      expect(page).to have_selector 'td', text: product.name

      expect(page).to have_select2 'order_distributor_id', with_options: [distributor1.name]
      expect(page).to_not have_select2 'order_distributor_id', with_options: [distributor2.name]

      expect(page).to have_select2 'order_order_cycle_id',
                                   with_options: ["#{order_cycle1.name} (open)"]
      expect(page).to_not have_select2 'order_order_cycle_id',
                                       with_options: ["#{order_cycle2.name} (open)"]

      click_button 'Update'

      expect(page).to have_selector 'h1', text: 'Customer Details'
      o = Spree::Order.last
      expect(o.distributor).to eq distributor1
      expect(o.order_cycle).to eq order_cycle1
    end
  end
end
