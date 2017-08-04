require 'spec_helper'

feature %q{
    As an administrator
    I want to manage enterprise fees
}, js: true do
  include AuthenticationWorkflow
  include WebHelper

  let!(:tax_category_gst) { create(:tax_category, name: 'GST') }

  scenario "listing enterprise fees" do
    fee = create(:enterprise_fee, name: '$0.50 / kg', fee_type: 'packing', tax_category: tax_category_gst)
    amount = fee.calculator.preferred_amount

    login_to_admin_section
    click_link 'Configuration'
    click_link 'Enterprise Fees'

    page.should have_select "enterprise_fee_set_collection_attributes_0_enterprise_id"
    page.should have_select "enterprise_fee_set_collection_attributes_0_fee_type", selected: 'Packing'
    page.should have_selector "input[value='$0.50 / kg']"
    page.should have_select "enterprise_fee_set_collection_attributes_0_tax_category_id", selected: 'GST'
    page.should have_select "enterprise_fee_set_collection_attributes_0_calculator_type", selected: 'Flat Rate (per item)'
    page.should have_selector "input[value='#{amount}']"
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
    select 'GST', from: 'enterprise_fee_set_collection_attributes_0_tax_category_id'
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
    enterprise = create(:enterprise, name: 'Foo')

    # When I go to the enterprise fees page
    login_to_admin_section
    click_link 'Configuration'
    click_link 'Enterprise Fees'

    # And I update the fields for the enterprise fee and click update
    select 'Foo', from: 'enterprise_fee_set_collection_attributes_0_enterprise_id'
    select 'Admin', from: 'enterprise_fee_set_collection_attributes_0_fee_type'
    fill_in 'enterprise_fee_set_collection_attributes_0_name', with: 'Greetings!'
    select 'Inherit From Product', from: 'enterprise_fee_set_collection_attributes_0_tax_category_id'
    select 'Flat Percent', from: 'enterprise_fee_set_collection_attributes_0_calculator_type'
    click_button 'Update'

    # Then I should see the updated fields for my fee
    page.should have_select "enterprise_fee_set_collection_attributes_0_enterprise_id", selected: 'Foo'
    page.should have_select "enterprise_fee_set_collection_attributes_0_fee_type", selected: 'Admin'
    page.should have_selector "input[value='Greetings!']"
    page.should have_select 'enterprise_fee_set_collection_attributes_0_tax_category_id', selected: 'Inherit From Product'
    page.should have_selector "option[selected]", text: 'Flat Percent (per item)'

    fee.reload
    fee.enterprise.should == enterprise
    fee.name.should == 'Greetings!'
    fee.fee_type.should == 'admin'
    fee.calculator_type.should == "Calculator::FlatPercentPerItem"

    # Sets tax_category and inherits_tax_category
    fee.tax_category.should == nil
    fee.inherits_tax_category.should == true
  end

  scenario "deleting an enterprise fee" do
    # Given an enterprise fee
    fee = create(:enterprise_fee)

    # When I go to the enterprise fees page
    login_to_admin_section
    click_link 'Configuration'
    expect(page).to have_link 'Enterprise Fees'
    click_link 'Enterprise Fees'
    expect(page).to have_content 'Enterprise Fees'

    # And I click delete
    find("a.delete-resource").click

    # Then my enterprise fee should have been deleted
    visit admin_enterprise_fees_path
    expect(page).to have_no_selector "input[value='#{fee.name}']"
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

  context "as an enterprise manager" do
    let(:enterprise_user) { create_enterprise_user }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Second Distributor') }
    let(:distributor3) { create(:distributor_enterprise, name: 'Third Distributor') }
    let(:ef1) { create(:enterprise_fee, name: 'One', enterprise: distributor1) }
    let(:ef2) { create(:enterprise_fee, name: 'Two', enterprise: distributor2) }

    before(:each) do
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor2).save
      login_to_admin_as enterprise_user
    end

    it "creates enterprise fees" do
      ef2

      click_link 'Enterprises'
      within("#e_#{distributor1.id}") { click_link 'Manage' }
      within(".side_menu") { click_link 'Enterprise Fees' }
      click_link "Create One Now"

      select distributor1.name, :from => 'enterprise_fee_set_collection_attributes_0_enterprise_id'
      fill_in 'enterprise_fee_set_collection_attributes_0_name', :with => 'foo'
      select 'GST', from: 'enterprise_fee_set_collection_attributes_0_tax_category_id'
      select 'Flat Percent', :from => 'enterprise_fee_set_collection_attributes_0_calculator_type'
      click_button 'Update'

      flash_message.should == 'Your enterprise fees have been updated.'

      # After saving, we should be redirected to the fees for our chosen enterprise
      page.should_not have_select 'enterprise_fee_set_collection_attributes_1_enterprise_id', selected: 'Second Distributor'

      enterprise_fee = EnterpriseFee.find_by_name 'foo'
      enterprise_fee.enterprise.should == distributor1
    end

    pending "shows me only enterprise fees for the enterprise I select" do
      ef1
      ef2

      click_link 'Enterprises'
      within("#e_#{distributor1.id}") { click_link 'Manage' }
      within(".side_menu") { click_link 'Enterprise Fees' }
      click_link "Manage Enterprise Fees"
      page.should     have_field 'enterprise_fee_set_collection_attributes_0_name', with: 'One'
      page.should_not have_field 'enterprise_fee_set_collection_attributes_1_name', with: 'Two'

      click_link 'Enterprises'
      within("#e_#{distributor2.id}") { click_link 'Manage' }
      within(".side_menu") { click_link 'Enterprise Fees' }
      click_link "Manage Enterprise Fees"
      page.should_not have_field 'enterprise_fee_set_collection_attributes_0_name', with: 'One'
      page.should     have_field 'enterprise_fee_set_collection_attributes_0_name', with: 'Two'
    end

    it "only allows me to select enterprises I have access to" do
      ef1
      ef2
      distributor3

      click_link 'Enterprises'
      within("#e_#{distributor2.id}") { click_link 'Manage' }
      within(".side_menu") { click_link 'Enterprise Fees' }
      click_link "Manage Enterprise Fees"
      page.should have_select('enterprise_fee_set_collection_attributes_1_enterprise_id',
                              selected: 'Second Distributor',
                              options: ['', 'First Distributor', 'Second Distributor'])
    end
  end
end
