# frozen_string_literal: true

require 'spec_helper'

feature '
    As an administrator
    I want to list and filter order cycles
', js: true do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  scenario "listing and filtering order cycles" do
    # Given some order cycles (created in an arbitrary order)
    oc4 = create(:simple_order_cycle, name: 'oc4',
                                      orders_open_at: 2.days.from_now, orders_close_at: 1.month.from_now)
    oc2 = create(:simple_order_cycle, name: 'oc2', orders_close_at: 1.month.from_now)
    oc6 = create(:simple_order_cycle, name: 'oc6',
                                      orders_open_at: 1.month.ago, orders_close_at: 3.weeks.ago)
    oc3 = create(:simple_order_cycle, name: 'oc3',
                                      orders_open_at: 1.day.from_now, orders_close_at: 1.month.from_now)
    oc5 = create(:simple_order_cycle, name: 'oc5',
                                      orders_open_at: 1.month.ago, orders_close_at: 2.weeks.ago)
    oc1 = create(:order_cycle, name: 'oc1')
    oc0 = create(:simple_order_cycle, name: 'oc0',
                                      orders_open_at: nil, orders_close_at: nil)
    oc7 = create(:simple_order_cycle, name: 'oc7',
                                      orders_open_at: 2.months.ago, orders_close_at: 5.weeks.ago)
    schedule1 = create(:schedule, name: 'Schedule1', order_cycles: [oc1, oc3])
    create(:proxy_order, subscription: create(:subscription, schedule: schedule1), order_cycle: oc1)

    # When I go to the admin order cycles page
    login_as_admin_and_visit admin_order_cycles_path

    # Then the order cycles should be ordered correctly
    expect(page).to have_selector "#listing_order_cycles tr td:first-child", count: 7

    order_cycle_names = ["oc0", "oc1", "oc2", "oc3", "oc4", "oc5", "oc6"]
    expect(all("#listing_order_cycles tr td:first-child input").map(&:value)).to eq order_cycle_names

    # And the rows should have the correct classes
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}.undated"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}.open"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}.open"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc3.id}.upcoming"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc4.id}.upcoming"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc5.id}.closed"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc6.id}.closed"

    toggle_columns "Producers", "Shops"

    # And I should see all the details for an order cycle
    within('table#listing_order_cycles tbody tr:nth-child(2)') do
      # Then I should see the basic fields
      expect(page).to have_input "oc#{oc1.id}[name]", value: oc1.name
      expect(page).to have_input "oc#{oc1.id}[orders_open_at]", value: oc1.orders_open_at,
                                                                visible: false
      expect(page).to have_input "oc#{oc1.id}[orders_close_at]", value: oc1.orders_close_at,
                                                                 visible: false
      expect(page).to have_content oc1.coordinator.name

      # And I should see the suppliers and distributors
      oc1.suppliers.each    { |s| expect(page).to have_content s.name }
      oc1.distributors.each { |d| expect(page).to have_content d.name }

      # And I should see the number of variants
      expect(page).to have_selector 'td.products', text: '2 variants'
    end

    # I can load more order_cycles
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc7.id}"
    click_button "Show 30 more days"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc7.id}"

    # I can filter order cycle by involved enterprises
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    select2_select oc1.suppliers.first.name, from: "involving_filter"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    select2_select "Any Enterprise", from: "involving_filter"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"

    # I can filter order cycles by name
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    fill_in "query", with: oc0.name
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    fill_in "query", with: ''
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"

    # I can filter order cycle by schedule
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc3.id}"
    select2_select schedule1.name, from: "schedule_filter"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc3.id}"
    select2_select 'Any Schedule', from: "schedule_filter"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc3.id}"

    # Attempting to edit dates of an open order cycle with active subscriptions
    find("#oc#{oc1.id}_orders_open_at").click
    expect(page).to have_selector "#confirm-dialog .message",
                                  text: I18n.t('admin.order_cycles.date_warning.msg', n: 1)
  end

  describe 'listing order cycles with other locales' do
    let!(:oc_pt) { create(:simple_order_cycle, name: 'oc', orders_open_at: '2012-01-01 00:00') }

    around(:each) do |spec|
      I18n.locale = :pt
      spec.run
      I18n.locale = :en
    end

    context 'using datepickers' do
      it "correctly opens the datepicker and changes the date field" do
        login_as_admin_and_visit admin_order_cycles_path

        within("tr.order-cycle-#{oc_pt.id}") do
          expect(find('input.datetimepicker', match: :first).value).to start_with '2012-01-01 00:00'
          find('input.datetimepicker', match: :first).click
        end

        within(".flatpickr-calendar.open") do
          expect(page).to have_selector '.flatpickr-day.selected', text: '1'
          find('.dayContainer .flatpickr-day', text: "30").click
        end

        within("tr.order-cycle-#{oc_pt.id}") do
          expect(find('input.datetimepicker', match: :first).value).to eq '2012-01-30 00:00'
        end
      end
    end
  end

  private

  def wait_for_edit_form_to_load_order_cycle(order_cycle)
    expect(page).to have_field "order_cycle_name", with: order_cycle.name
  end

  def select_incoming_variant(supplier, exchange_no, variant)
    page.find("table.exchanges tr.supplier-#{supplier.id} td.products").click
    check "order_cycle_incoming_exchange_#{exchange_no}_variants_#{variant.id}"
  end
end
