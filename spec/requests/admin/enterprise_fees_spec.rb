require 'spec_helper'

feature %q{
    As an administrator
    I want to manage enterprise fees
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "listing enterprise fees" do
    fee = create(:enterprise_fee)

    login_to_admin_section
    click_link 'Configuration'
    click_link 'Enterprise Fees'

    page.should have_selector 'option', :text => fee.enterprise.name
    page.should have_selector 'option', :text => 'Packing'
    page.should have_selector "input[value='$0.50 / kg']"
    page.should have_selector 'option', :text => 'Weight (per kg)'
    page.should have_selector "input[value='0.5']"
  end
end
