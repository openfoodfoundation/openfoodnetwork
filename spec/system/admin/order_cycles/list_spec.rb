# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
    As an administrator
    I want to list and filter order cycles
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  let(:hub) { create(:distributor_enterprise, with_payment_and_shipping: true) }

  it "listing and filtering order cycles" do
    # Given some order cycles (created in an arbitrary order)
    oc4 = create(:simple_order_cycle, name: 'oc4',
                                      orders_open_at: 2.days.from_now,
                                      orders_close_at: 1.month.from_now, distributors: [hub])
    oc2 = create(:simple_order_cycle, name: 'oc2',
                                      orders_close_at: 1.month.from_now, distributors: [hub])
    oc6 = create(:simple_order_cycle, name: 'oc6',
                                      orders_open_at: 1.month.ago, orders_close_at: 3.weeks.ago,
                                      distributors: [hub])
    oc3 = create(:simple_order_cycle, name: 'oc3',
                                      orders_open_at: 1.day.from_now,
                                      orders_close_at: 1.month.from_now,
                                      distributors: [hub])
    oc5 = create(:simple_order_cycle, name: 'oc5',
                                      orders_open_at: 1.month.ago, orders_close_at: 2.weeks.ago,
                                      distributors: [hub])
    oc1 = create(:order_cycle, name: 'oc1', distributors: [hub])
    oc0 = create(:simple_order_cycle, name: 'oc0',
                                      orders_open_at: nil, orders_close_at: nil,
                                      distributors: [hub])
    oc7 = create(:simple_order_cycle, name: 'oc7',
                                      orders_open_at: 2.months.ago, orders_close_at: 5.weeks.ago,
                                      distributors: [hub])
    schedule1 = create(:schedule, name: 'Schedule1', order_cycles: [oc1, oc3])
    create(:proxy_order, subscription: create(:subscription, schedule: schedule1), order_cycle: oc1)

    # When I go to the admin order cycles page
    login_as_admin
    visit admin_order_cycles_path

    # Then the order cycles should be ordered correctly
    expect(page).to have_selector "#listing_order_cycles tr td:first-child", count: 7

    order_cycle_names = ["oc0", "oc1", "oc2", "oc3", "oc4", "oc5", "oc6"]
    expect(all("#listing_order_cycles tr td:first-child input").map(&:value))
      .to eq order_cycle_names

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
    expect(page).not_to have_selector "#listing_order_cycles tr.order-cycle-#{oc7.id}"
    click_button "Show 30 more days"

    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc7.id}"

    # I can filter order cycle by involved enterprises
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    select2_select oc1.suppliers.first.name, from: "involving_filter"
    expect(page).not_to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).not_to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
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
    expect(page).not_to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).not_to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
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
    expect(page).not_to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).not_to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc3.id}"
    select2_select 'Any Schedule', from: "schedule_filter"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc3.id}"

    # Attempting to edit dates of an open order cycle with active subscriptions
    find("#oc#{oc1.id}_orders_open_at").click
    expect(page).to have_selector "#confirm-dialog .message",
                                  text: date_warning_msg(1)
  end

  describe 'listing order cycles with other locales' do
    oc_open_at = 2.weeks.ago
    oc_close_at = 2.weeks.from_now
    let!(:oc_pt) {
      create(:simple_order_cycle, name: 'oc', orders_open_at: oc_open_at,
                                  orders_close_at: oc_close_at)
    }

    around(:each) do |spec|
      I18n.with_locale(:pt) do
        spec.run
      end
    end

    context 'using datetimepickers' do
      it "correctly opens the datetimepicker and changes the date field" do
        login_as_admin
        visit admin_order_cycles_path

        within("tr.order-cycle-#{oc_pt.id}") do
          expect(find('input.datetimepicker',
                      match: :first).value).to start_with oc_open_at.strftime("%Y-%m-%d %H:%M")
          find('input.datetimepicker', match: :first).click
        end

        within(".flatpickr-calendar.open") do
          # we need to strip leading zeros, ex.: 09 -> 9
          date_picker_selection = oc_open_at.strftime("%d").to_i.to_s
          expect(page).to have_selector '.flatpickr-day.selected', text: date_picker_selection
          find('.dayContainer .flatpickr-day', text: "13").click
        end

        within("tr.order-cycle-#{oc_pt.id}") do
          expect(find('input.datetimepicker',
                      match: :first).value).to eq oc_open_at.strftime("%Y-%m-13 %H:%M")
        end
      end

      it "correctly opens the datetimepicker and closes it using the last button " \
         "(the 'Close' one)" do
        login_as_admin
        visit admin_order_cycles_path
        test_value = Time.zone.now

        # Opens a datetimepicker
        within("tr.order-cycle-#{oc_pt.id}") do
          find('input.datetimepicker', match: :first).click
        end

        select_datetime_from_datepicker test_value
        close_datepicker

        # Should no more have opened flatpickr
        expect(page).not_to have_selector '.flatpickr-calendar.open'

        # Check the value is correct
        within("tr.order-cycle-#{oc_pt.id}") do
          expect(find('input.datetimepicker',
                      match: :first).value).to eq test_value.to_datetime.strftime("%Y-%m-%d %H:%M")
        end
      end
    end
  end
  describe 'updating order cycles' do
    let!(:order_cycle) { create(:simple_order_cycle) }
    before(:each) do
      login_as_admin
      visit admin_order_cycles_path
    end

    context 'with attached order cycles' do
      let!(:order) { create(:order, order_cycle: ) }
      it('renders warning modal with datetime value changed') do
        within("tr.order-cycle-#{order_cycle.id}") do
          find('input.datetimepicker', match: :first).click
        end
        select_datetime_from_datepicker Time.zone.parse("2024-03-30 00:00")
        close_datepicker
        expect(page).to have_content('You have unsaved changes')

        # click save to open warning modal
        click_button('Save')
        expect(page).to have_content('You have unsaved changes')
        expect(page).to have_content "Orders are linked to this order cycle."

        # confirm to close modal and update order cycle changed fields
        click_button('Proceed anyway')
        expect(page).not_to have_content "Orders are linked to this cycle"
        expect(page).to have_content('Order cycles have been updated.')
      end
    end

    context 'with no attached order cycles' do
      it('renders warnig modal with datetime value changed') do
        within("tr.order-cycle-#{order_cycle.id}") do
          find('input.datetimepicker', match: :first).click
        end
        select_datetime_from_datepicker Time.zone.parse("2024-03-30 00:00")
        close_datepicker
        expect(page).to have_content('You have unsaved changes')

        click_button('Save')
        expect(page).not_to have_content "Orders are linked to this order cycle."
        expect(page).to have_content('Order cycles have been updated.')
      end
    end
  end

  private

  def date_warning_msg(nbr = 1)
    "This order cycle is linked to %d open subscription orders. Changing this date now will not " \
    "affect any orders which have already been placed, but should be avoided if possible. " \
    "Are you sure you want to proceed?" % nbr
  end
end
