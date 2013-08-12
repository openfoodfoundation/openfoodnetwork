require 'spec_helper'

feature %q{
    As an administrator
    I want to manage enterprise fees
}, js: true do
  include AuthenticationWorkflow
  include WebHelper
  
  before :all do
    @default_wait_time = Capybara.default_wait_time
    Capybara.default_wait_time = 5
  end
  
  after :all do
    Capybara.default_wait_time = @default_wait_time
  end

  scenario "listing enterprise fees" do
    fee = create(:enterprise_fee, name: '$0.50 / kg')

    login_to_admin_section
    click_link 'Configuration'
    click_link 'Enterprise Fees'

    page.should have_selector "#enterprise_fee_set_collection_attributes_0_enterprise_id"
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
    find("a.delete-resource").click

    # Then my enterprise fee should have been deleted
    visit admin_enterprise_fees_path
    page.should_not have_selector "input[value='#{fee.name}']"
  end

  scenario "deleting a shipping method referenced by a product distribution" do
    # Given an enterprise fee referenced by a product distribution
    fee = create(:enterprise_fee)
    p = create(:product)
    d = create(:distributor_enterprise)
    create(:product_distribution, product: p, distributor: d, enterprise_fee: fee)

    # When I go to the enterprise fees page
    login_to_admin_section
    click_link 'Configuration'
    click_link 'Enterprise Fees'

    # And I click delete
    find("a.delete-resource").click

    # Then I should see an error
    page.should have_content "That enterprise fee cannot be deleted as it is referenced by a product distribution: #{p.id} - #{p.name}."

    # And my enterprise fee should not have been deleted
    visit admin_enterprise_fees_path
    page.should have_selector "input[value='#{fee.name}']"
    EnterpriseFee.find(fee.id).should_not be_nil
  end
end
