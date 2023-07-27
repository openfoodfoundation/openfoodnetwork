# frozen_string_literal: true

require "system_helper"

describe "Test Flatpickr" do
  include AuthenticationHelper
  include WebHelper

  context "orders" do
    it "opens the datepicker and closes it using the 'CLOSE' button" do
      login_as_admin
      visit 'admin/orders'
      open_datepicker('.datepicker')
      # Looks for the close button and click it
      within(".flatpickr-calendar.open") do
        expect(page).to have_selector '.shortcut-buttons-flatpickr-buttons'
        find("button", text: "CLOSE").click
      end
      # Should no more have opened flatpickr
      expect(page).not_to have_selector '.flatpickr-calendar.open'
    end

    it "opens the datepicker and closes it by clicking outside" do
      login_as_admin
      visit 'admin/orders'
      open_datepicker('.datepicker')
      find("#admin-menu").click
      # Should no more have opened flatpickr
      expect(page).not_to have_selector '.flatpickr-calendar.open'
    end
  end

  private

  def open_datepicker(field)
    # Opens a datepicker
    find(field).click
    # Should have opened flatpickr
    expect(page).to have_selector '.flatpickr-calendar.open'
  end

  def check_fielddate(field, date)
    # Check the value is correct
    expect(find(field, match: :first).value).to eq date.to_datetime.strftime("%Y-%m-%d")
  end
end
