require "spec_helper"

feature %q{
    As an administrator
    I want to manage adjustments on orders
} do
  include AuthenticationWorkflow
  include WebHelper

  let!(:user) { create(:user) }
  let!(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }

  let!(:order) { create(:order_with_totals_and_distribution, user: user, distributor: distributor, order_cycle: order_cycle, state: 'complete', payment_state: 'balance_due') }
  let!(:tax_rate) { create(:tax_rate, name: 'GST', calculator: build(:calculator, preferred_amount: 10), zone: create(:zone_with_member)) }

  before do
    order.finalize!
    create(:check_payment, order: order, amount: order.total)
  end

  scenario "adding taxed adjustments to an order" do
    # When I go to the adjustments page for the order
    login_to_admin_section
    visit spree.admin_orders_path
    page.find('td.actions a.icon-edit').click
    click_link 'Adjustments'

    # And I create a new adjustment with tax
    click_link 'New Adjustment'
    fill_in 'adjustment_amount', with: 110
    fill_in 'adjustment_label', with: 'Late fee'
    select 'GST', from: 'tax_rate_id'
    click_button 'Continue'

    # Then I should see the adjustment, with the correct tax
    page.should have_selector 'td.label', text: 'Late fee'
    page.should have_selector 'td.amount', text: '110'
    page.should have_selector 'td.included-tax', text: '10'
  end

  scenario "modifying taxed adjustments on an order" do
    # Given a taxed adjustment
    adjustment = create(:adjustment, adjustable: order, amount: 110, included_tax: 10)

    # When I go to the adjustments page for the order
    login_to_admin_section
    visit spree.admin_orders_path
    page.find('td.actions a.icon-edit').click
    click_link 'Adjustments'
    page.find('tr', text: 'Shipping').find('a.icon-edit').click

    # Then I should see the uneditable included tax and our tax rate as the default
    page.should have_field :adjustment_included_tax, with: '10.00', disabled: true
    page.should have_select :tax_rate_id, selected: 'GST'

    # When I edit the adjustment, removing the tax
    select 'Remove tax', from: :tax_rate_id
    click_button 'Continue'

    # Then the adjustment tax should be cleared
    page.should have_selector 'td.amount', text: '110'
    page.should have_selector 'td.included-tax', text: '0'
  end

  scenario "modifying an untaxed adjustment on an order" do
    # Given an untaxed adjustment
    adjustment = create(:adjustment, adjustable: order, amount: 110, included_tax: 0)

    # When I go to the adjustments page for the order
    login_to_admin_section
    visit spree.admin_orders_path
    page.find('td.actions a.icon-edit').click
    click_link 'Adjustments'
    page.find('tr', text: 'Shipping').find('a.icon-edit').click

    # Then I should see the uneditable included tax and 'Remove tax' as the default tax rate
    page.should have_field :adjustment_included_tax, with: '0.00', disabled: true
    page.should have_select :tax_rate_id, selected: []

    # When I edit the adjustment, setting a tax rate
    select 'GST', from: :tax_rate_id
    click_button 'Continue'

    # Then the adjustment tax should be recalculated
    page.should have_selector 'td.amount', text: '110'
    page.should have_selector 'td.included-tax', text: '10'
  end
end
