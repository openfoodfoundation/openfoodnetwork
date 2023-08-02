# frozen_string_literal: true

require "system_helper"

describe '
    As an administrator
    I want to manage adjustments on orders
' do
  include AuthenticationHelper
  include WebHelper

  let!(:user) { create(:user) }
  let!(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }

  let!(:order) {
    create(:order_with_totals_and_distribution, user: user, distributor: distributor,
                                                order_cycle: order_cycle, state: 'complete',
                                                payment_state: 'balance_due')
  }
  let!(:tax_category) { create(:tax_category, name: 'GST') }
  let!(:tax_rate) {
    create(:tax_rate, name: 'GST', calculator: build(:calculator, preferred_amount: 10),
                      zone: create(:zone_with_member), tax_category: tax_category)
  }

  let!(:tax_category_included) { create(:tax_category, name: 'TVA 20%', is_default: true) }
  let!(:default_tax_zone) { create(:zone, default_tax: true) }
  let!(:tax_rate2) {
    create(:tax_rate, name: "TVA 20%", amount: 0.2, zone: default_tax_zone, included_in_price: true,
                      tax_category: tax_category_included, calculator: Calculator::DefaultTax.new )
  }

  before do
    order.finalize!
    create(:check_payment, order: order, amount: order.total)
    login_as_admin
    visit spree.admin_orders_path
  end

  shared_examples "when the enable_localized_number preference" \
    do |adjustment_label, adjustment_amount, tax_category, tax, tax_total|
    it "creates the adjustment and calculates taxes" do
      # When I go to the adjustments page for the order
      page.find('td.actions a.icon-edit').click
      click_link 'Adjustments'

      # And I create a new adjustment with tax
      click_link 'New Adjustment'
      fill_in 'adjustment_amount', with: adjustment_amount
      fill_in 'adjustment_label', with: adjustment_label
      select tax_category.to_s, from: 'adjustment_tax_category_id'
      click_button 'Continue'

      # Then I should see the adjustment, with tax included in the amount
      expect(page).to have_selector 'td.label', text: adjustment_label.to_s
      expect(page).to have_selector 'td.amount', text: adjustment_amount.to_s
      expect(page).to have_selector 'td.tax-category', text: tax_category.to_s
      expect(page).to have_selector 'td.tax', text: tax.to_s
      expect(page).to have_selector 'td.total', text: tax_total.to_s
    end
  end

  context "is active" do
    before do
      allow(Spree::Config).to receive(:enable_localized_number?).and_return(true)
    end

    context "included tax" do
      context "adding negative, taxed adjustments to an order" do
        it_behaves_like "when the enable_localized_number preference",
                        "Discount", "-2", "TVA 20%", "$0.33", "$-1.67"
      end

      context "adding positive, taxed adjustments to an order" do
        it_behaves_like "when the enable_localized_number preference",
                        "Late fee", "100", "TVA 20%", "$-16.67", "$83.33"
      end
    end

    context "added tax" do
      context "adding negative, taxed adjustments to an order" do
        it_behaves_like "when the enable_localized_number preference",
                        "Discount", "-2", "GST", "$10.00", "$8.00"
      end

      context "adding positive, taxed adjustments to an order" do
        it_behaves_like "when the enable_localized_number preference",
                        "Late fee", "110", "GST", "$10.00", "$120"
      end
    end
  end

  context "is not active" do
    before do
      allow(Spree::Config).to receive(:enable_localized_number?).and_return(false)
    end

    context "included tax" do
      context "adding negative, taxed adjustments to an order" do
        it_behaves_like "when the enable_localized_number preference",
                        "Discount", "-2", "TVA 20%", "$0.33", "$-1.67"
      end

      context "adding positive, taxed adjustments to an order" do
        it_behaves_like "when the enable_localized_number preference",
                        "Late fee", "100", "TVA 20%", "$-16.67", "$83.33"
      end
    end

    context "added tax" do
      context "adding negative, taxed adjustments to an order" do
        it_behaves_like "when the enable_localized_number preference",
                        "Discount", "-2", "GST", "$10.00", "$8.00"
      end

      context "adding positive, taxed adjustments to an order" do
        it_behaves_like "when the enable_localized_number preference",
                        "Late fee", "110", "GST", "$10.00", "$120"
      end
    end
  end

  it "modifying taxed adjustments on an order" do
    # Given a taxed adjustment
    adjustment = create(:adjustment, label: "Extra Adjustment", adjustable: order,
                                     amount: 110, tax_category: tax_category, order: order)

    # When I go to the adjustments page for the order
    page.find('td.actions a.icon-edit').click
    click_link 'Adjustments'
    page.find('tr', text: 'Extra Adjustment').find('a.icon-edit').click

    expect(page).to have_select2 :adjustment_tax_category_id, selected: 'GST'

    # When I edit the adjustment, removing the tax
    select2_select 'None', from: :adjustment_tax_category_id
    click_button 'Continue'

    # Then the adjustment tax should be cleared
    expect(page).to have_selector 'td.amount', text: '110.00'
    expect(page).to have_selector 'td.tax', text: '0.00'
  end

  it "modifying an untaxed adjustment on an order" do
    # Given an untaxed adjustment
    adjustment = create(:adjustment, label: "Extra Adjustment", adjustable: order,
                                     amount: 110, tax_category: nil, order: order)

    # When I go to the adjustments page for the order
    page.find('td.actions a.icon-edit').click
    click_link 'Adjustments'
    page.find('tr', text: 'Extra Adjustment').find('a.icon-edit').click

    expect(page).to have_select2 :adjustment_tax_category_id, selected: []

    # When I edit the adjustment, setting a tax rate
    select2_select 'GST', from: :adjustment_tax_category_id
    click_button 'Continue'

    # Then the adjustment tax should be recalculated
    expect(page).to have_selector 'td.amount', text: '110.00'
    expect(page).to have_selector 'td.tax', text: '10.00'
  end

  context "on a canceled order" do
    # Given a taxed adjustment
    let!(:adjustment) {
      create(:adjustment, label: "Extra Adjustment", adjustable: order,
                          amount: 110, tax_category: tax_category, order: order)
    }
    before do
      order.cancel!
      login_as_admin
      visit spree.edit_admin_order_path(order)
    end

    it "displays adjustments" do
      click_link 'Adjustments'

      expect(page).to_not have_selector 'tr a.icon-edit'
      expect(page).to_not have_selector 'a.icon-plus', text: 'New Adjustment'
    end
  end
end
