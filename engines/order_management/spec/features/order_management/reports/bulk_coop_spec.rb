# frozen_string_literal: true

require "spec_helper"

feature "bulk coop" do
  include AuthenticationWorkflow
  include WebHelper

  scenario "bulk co-op report" do
    quick_login_as_admin
    visit spree.admin_reports_path
    click_link 'Bulk Co-Op'
    click_button 'Generate Report'

    expect(page).to have_content 'Supplier'
  end
end
