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

    page.should have_selector 'option', text: fee.enterprise.name
    page.should have_selector 'option', text: 'Packing'
    page.should have_selector "input[value='$0.50 / kg']"
    page.should have_selector 'option', text: 'Weight (per kg)'
    page.should have_selector "input[value='0.5']"
  end

  scenario "creating an enterprise fee" do
    # Given an enterprise
    e = create(:supplier_enterprise, name: 'Feedme')

    # When I go to the enterprise fees page
    login_to_admin_section
    click_link 'Configuration'
    click_link 'Enterprise Fees'

    # And I fill in the fields for a new enterprise fee and click update
    select 'Feedme', from: 'enterprise_fee_set_collection_attributes_0_enterprise_id'
    select 'Admin', from: 'enterprise_fee_set_collection_attributes_0_fee_type'
    fill_in 'enterprise_fee_set_collection_attributes_0_name', with: 'Hello!'
    select 'Flat Percent', from: 'enterprise_fee_set_collection_attributes_0_calculator_type'
    click_button 'Update'

    # Then I should see my fee and fields for the calculator
    page.should have_content "Your enterprise fees have been updated."
    page.should have_selector "input[value='Hello!']"

    # When I fill in the calculator fields and click update
    fill_in 'enterprise_fee_set_collection_attributes_0_calculator_attributes_preferred_flat_percent', with: '12.34'
    click_button 'Update'

    # Then I should see the correct values in my calculator fields
    page.should have_selector "#enterprise_fee_set_collection_attributes_0_calculator_attributes_preferred_flat_percent[value='12.34']"
  end

end
