# frozen_string_literal: true

require "system_helper"

describe "Test Flatpickr", js: true do
  include AuthenticationHelper
  include WebHelper

  context "orders" do
    it "opens the datepicker and closes it using the 'CLOSE' button" do
      login_as_admin_and_visit 'admin/orders'
      open_datepicker('#q_completed_at_gteq')       
      # Looks for the close button and click it
      within(".flatpickr-calendar.open") do
        expect(page).to have_selector '.shortcut-buttons-flatpickr-buttons'
        find("button", text: "CLOSE").click
      end
      # Should no more have opened flatpickr
      expect(page).not_to have_selector '.flatpickr-calendar.open'
    end
    
    it "opens the datepicker and sets date to today" do
      login_as_admin_and_visit 'admin/orders'
      open_datepicker('#q_completed_at_gteq')
      choose_today_from_datepicker
      check_fielddate('#q_completed_at_gteq', Date.today())       
    end
    
    it "opens the datepicker and closes it by clicking outside" do
      login_as_admin_and_visit 'admin/orders'
      open_datepicker('#q_completed_at_gteq')
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
