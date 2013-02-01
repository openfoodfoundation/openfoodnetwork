require 'spec_helper'

feature %q{
    As an administrator
    I want to manage enterprise fees
}, js: true do
  include AuthenticationWorkflow
  include WebHelper

  scenario "listing enterprise fees" do
    fee = create(:enterprise_fee)

    login_to_admin_section
    click_link 'Configuration'
    click_link 'Enterprise Fees'

    page.should have_selector "option[selected]", text: fee.enterprise.name
    page.should have_selector "option[selected]", text: 'Packing'
    page.should have_selector "input[value='$0.50 / kg']"
    page.should have_selector "option[selected]", text: 'Weight (per kg)'
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

  scenario "editing an enterprise fee" do
    # Given an enterprise fee
    fee = create(:enterprise_fee)
    create(:enterprise, name: 'Foo')

    # When I go to the enterprise fees page
    login_to_admin_section
    click_link 'Configuration'
    click_link 'Enterprise Fees'

    # And I update the fields for the enterprise fee and click update
    select 'Foo', from: 'enterprise_fee_set_collection_attributes_0_enterprise_id'
    select 'Admin', from: 'enterprise_fee_set_collection_attributes_0_fee_type'
    fill_in 'enterprise_fee_set_collection_attributes_0_name', with: 'Greetings!'
    select 'Flat Percent', from: 'enterprise_fee_set_collection_attributes_0_calculator_type'
    click_button 'Update'

    # Then I should see the updated fields for my fee
    page.should have_selector "option[selected]", text: 'Foo'
    page.should have_selector "option[selected]", text: 'Admin'
    page.should have_selector "input[value='Greetings!']"
    page.should have_selector "option[selected]", text: 'Flat Percent'
  end

  scenario "deleting an enterprise fee" do
    # Given an enterprise fee
    fee = create(:enterprise_fee)

    # When I go to the enterprise fees page
    login_to_admin_section
    click_link 'Configuration'
    click_link 'Enterprise Fees'

    # And I click delete
    click_link 'Delete'
    page.driver.browser.switch_to.alert.accept

    # Then my enterprise fee should have been deleted
    visit admin_enterprise_fees_path
    page.should_not have_selector "input[value='#{fee.name}']"
  end

end
