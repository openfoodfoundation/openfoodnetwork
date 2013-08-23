require "spec_helper"

feature %q{
    As a payment administrator
    I want to capture multiple payments quickly from the one page
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    @user = create(:user)
    @order = create(:order_with_totals_and_distributor, :user => @user, :state => 'complete', :payment_state => 'balance_due')

    # ensure order has a payment to capture
    @order.finalize!

    create :check_payment, order: @order, amount: @order.total
  end

  scenario "creating an order with distributor and order cycle", js: true do
    order_cycle = create(:order_cycle)
    distributor = order_cycle.distributors.first
    product = order_cycle.products.first

    login_to_admin_section

    click_link 'Orders'
    click_link 'New Order'

    page.should have_content 'ADD PRODUCT'
    targetted_select2_search product.name, from: '#add_variant_id', dropdown_css: '.select2-drop'
    click_link 'Add'
    page.has_selector? "table.index tbody[data-hook='admin_order_form_line_items'] tr"  # Wait for JS
    page.should have_selector 'td', text: product.name

    select distributor.name, from: 'order_distributor_id'
    select order_cycle.name, from: 'order_order_cycle_id'
    click_button 'Update'

    page.should have_selector 'h1', text: 'Customer Details'
    o = Spree::Order.last
    o.distributor.should == distributor
    o.order_cycle.should == order_cycle
  end

  it "can't change distributor and order cycle once order is created (or similar restriction)"

  scenario "capture multiple payments from the orders index page" do
    # d.cook: could also test for an order that has had payment voided, then a new check payment created but not yet captured. But it's not critical and I know it works anyway.

    login_to_admin_section

    click_link 'Orders'
    current_path.should == spree.admin_orders_path

    # click the 'capture' link for the order
    page.find("[data-action=capture][href*=#{@order.number}]").click

    flash_message.should == "Payment Updated"

    # check the order was captured
    @order.reload
    @order.payment_state.should == "paid"

    # we should still be on the same page
    current_path.should == spree.admin_orders_path
  end
end
