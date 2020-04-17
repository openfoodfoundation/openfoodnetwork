require "spec_helper"
include ActionView::Helpers::NumberHelper

feature '
    As an administrator
    I want to manage orders
', js: true do
  include AuthenticationWorkflow
  include WebHelper
  include CheckoutHelper

  background do
    @user = create(:user)
    @product = create(:simple_product)
    @distributor = create(:distributor_enterprise, owner: @user, charges_sales_tax: true)
    @order_cycle = create(:simple_order_cycle, name: 'One', distributors: [@distributor], variants: [@product.variants.first])

    @order = create(:order_with_totals_and_distribution, user: @user, distributor: @distributor, order_cycle: @order_cycle, state: 'complete', payment_state: 'balance_due')
    @customer = create(:customer, enterprise: @distributor, email: @user.email, user: @user, ship_address: create(:address))

    # ensure order has a payment to capture
    @order.finalize!

    create :check_payment, order: @order, amount: @order.total
  end

  scenario "order cycles appear in descending order by close date on orders page" do
    create(:simple_order_cycle, name: 'Two', orders_close_at: 2.weeks.from_now)
    create(:simple_order_cycle, name: 'Four', orders_close_at: 4.weeks.from_now)
    create(:simple_order_cycle, name: 'Three', orders_close_at: 3.weeks.from_now)

    quick_login_as_admin
    visit 'admin/orders'

    open_select2('#s2id_q_order_cycle_id_in')

    expect(find('#q_order_cycle_id_in', visible: :all)[:innerHTML]).to have_content(/.*Four.*Three.*Two.*One/m)
  end

  scenario "displays error when incorrect distribution for products is chosen" do
    d = create(:distributor_enterprise)
    oc = create(:simple_order_cycle, distributors: [d])

    # Move the order back to the cart state
    @order.state = 'cart'
    @order.completed_at = nil
    # A nil user keeps the order in the cart state
    #   Even if the edit page tries to automatically progress the order workflow
    @order.user = nil
    @order.save

    quick_login_as_admin
    visit '/admin/orders'
    uncheck 'Only show complete orders'
    page.find('a.icon-search').click

    click_icon :edit
    expect(page).to have_select2 "order_distributor_id", with_options: [d.name]
    select2_select d.name, from: 'order_distributor_id'
    select2_select oc.name, from: 'order_order_cycle_id'

    click_button 'Update And Recalculate Fees'
    expect(page).to have_content "Distributor or order cycle cannot supply the products in your cart"
  end

  scenario "can't add products to an order outside the order's hub and order cycle" do
    product = create(:simple_product)

    quick_login_as_admin
    visit '/admin/orders'
    page.find('td.actions a.icon-edit').click

    expect(page).not_to have_select2 "add_variant_id", with_options: [product.name]
  end

  scenario "can't change distributor or order cycle once order has been finalized" do
    quick_login_as_admin
    visit '/admin/orders'
    page.find('td.actions a.icon-edit').click

    expect(page).not_to have_select2 'order_distributor_id'
    expect(page).not_to have_select2 'order_order_cycle_id'

    expect(page).to have_selector 'p', text: "Distributor: #{@order.distributor.name}"
    expect(page).to have_selector 'p', text: "Order cycle: #{@order.order_cycle.name}"
  end

  scenario "capture payment from the orders index page" do
    quick_login_as_admin

    visit spree.admin_orders_path
    expect(page).to have_current_path spree.admin_orders_path

    # click the 'capture' link for the order
    page.find("[data-powertip=Capture]").click

    expect(page).to have_css "i.success"
    expect(page).to have_css "button.icon-road"

    # check the order was captured
    expect(@order.reload.payment_state).to eq "paid"

    # we should still be on the same page
    expect(page).to have_current_path spree.admin_orders_path
  end

  scenario "ship order from the orders index page" do
    @order.payments.first.capture!
    quick_login_as_admin
    visit spree.admin_orders_path

    page.find("[data-powertip=Ship]").click

    expect(page).to have_css "i.success"
    expect(@order.reload.shipments.any?(&:shipped?)).to be true
  end
end
