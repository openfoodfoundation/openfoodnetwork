# frozen_string_literal: true

require 'spec_helper'

feature '
    As an administrator
    I want to manage enterprise fees
', js: true do
  include WebHelper
  include AuthenticationHelper

  let!(:tax_category_gst) { create(:tax_category, name: 'GST') }

  scenario "listing enterprise fees" do
    fee = create(:enterprise_fee, name: '$0.50 / kg', fee_type: 'packing',
                                  tax_category: tax_category_gst)
    amount = fee.calculator.preferred_amount

    login_as_admin_and_visit spree.edit_admin_general_settings_path
    click_link 'Enterprise Fees'

    expect(page).to have_select "sets_enterprise_fee_set_collection_attributes_0_enterprise_id"
    expect(page).to have_select "sets_enterprise_fee_set_collection_attributes_0_fee_type",
                                selected: 'Packing fee'
    expect(page).to have_selector "input[value='$0.50 / kg']"
    expect(page).to have_select "sets_enterprise_fee_set_collection_attributes_0_tax_category_id",
                                selected: 'GST'
    expect(page).to have_select "sets_enterprise_fee_set_collection_attributes_0_calculator_type",
                                selected: 'Flat Rate (per item)'
    expect(page).to have_selector "input[value='#{amount}']"
  end

  scenario "creating an enterprise fee" do
    # Given an enterprise
    e = create(:supplier_enterprise, name: 'Feedme')

    # When I go to the enterprise fees page
    login_as_admin_and_visit admin_enterprise_fees_path

    # And I fill in the fields for a new enterprise fee and click update
    select 'Feedme', from: 'sets_enterprise_fee_set_collection_attributes_0_enterprise_id'
    select 'Admin', from: 'sets_enterprise_fee_set_collection_attributes_0_fee_type'
    fill_in 'sets_enterprise_fee_set_collection_attributes_0_name', with: 'Hello!'
    select 'GST', from: 'sets_enterprise_fee_set_collection_attributes_0_tax_category_id'
    select 'Flat Percent', from: 'sets_enterprise_fee_set_collection_attributes_0_calculator_type'
    click_button 'Update'

    # Then I should see my fee and fields for the calculator
    expect(page).to have_content "Your enterprise fees have been updated."
    expect(page).to have_selector "input[value='Hello!']"

    # When I fill in the calculator fields and click update
    fill_in 'sets_enterprise_fee_set_collection_attributes_0_calculator_attributes_preferred_flat_percent',
            with: '12.34'
    click_button 'Update'

    # Then I should see the correct values in my calculator fields
    expect(page).to have_selector "#sets_enterprise_fee_set_collection_attributes_0_calculator_attributes_preferred_flat_percent[value='12.34']"
  end

  scenario "editing an enterprise fee" do
    # Given an enterprise fee
    fee = create(:enterprise_fee)
    enterprise = create(:enterprise, name: 'Foo')

    # When I go to the enterprise fees page
    login_as_admin_and_visit admin_enterprise_fees_path

    # And I update the fields for the enterprise fee and click update
    select 'Foo', from: 'sets_enterprise_fee_set_collection_attributes_0_enterprise_id'
    select 'Admin', from: 'sets_enterprise_fee_set_collection_attributes_0_fee_type'
    fill_in 'sets_enterprise_fee_set_collection_attributes_0_name', with: 'Greetings!'
    select 'Inherit From Product',
           from: 'sets_enterprise_fee_set_collection_attributes_0_tax_category_id'
    select 'Flat Percent', from: 'sets_enterprise_fee_set_collection_attributes_0_calculator_type'
    click_button 'Update'

    # Then I should see the updated fields for my fee
    expect(page).to have_select "sets_enterprise_fee_set_collection_attributes_0_enterprise_id",
                                selected: 'Foo'
    expect(page).to have_select "sets_enterprise_fee_set_collection_attributes_0_fee_type",
                                selected: 'Admin fee'
    expect(page).to have_selector "input[value='Greetings!']"
    expect(page).to have_select 'sets_enterprise_fee_set_collection_attributes_0_tax_category_id',
                                selected: 'Inherit From Product'
    expect(page).to have_selector "option[selected]", text: 'Flat Percent (per item)'

    fee.reload
    expect(fee.enterprise).to eq(enterprise)
    expect(fee.name).to eq('Greetings!')
    expect(fee.fee_type).to eq('admin')
    expect(fee.calculator_type).to eq("Calculator::FlatPercentPerItem")

    # Sets tax_category and inherits_tax_category
    expect(fee.tax_category).to eq(nil)
    expect(fee.inherits_tax_category).to eq(true)
  end

  scenario "deleting an enterprise fee" do
    # Given an enterprise fee
    fee = create(:enterprise_fee)

    # When I go to the enterprise fees page
    login_as_admin_and_visit admin_enterprise_fees_path

    # And I click delete
    accept_alert do
      find("a.delete-resource").click
    end

    # Then my enterprise fee should have been deleted
    visit admin_enterprise_fees_path
    expect(page).to have_no_selector "input[value='#{fee.name}']"
  end

  context "as an enterprise manager" do
    let(:enterprise_user) { create(:user) }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Second Distributor') }
    let(:distributor3) { create(:distributor_enterprise, name: 'Third Distributor') }
    let(:ef1) { create(:enterprise_fee, name: 'One', enterprise: distributor1) }
    let(:ef2) { create(:enterprise_fee, name: 'Two', enterprise: distributor2) }

    before(:each) do
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor2).save
      login_as enterprise_user
    end

    it "creates enterprise fees" do
      visit edit_admin_enterprise_path(distributor1)
      within(".side_menu") { click_link 'Enterprise Fees' }
      click_link "Create One Now"

      select distributor1.name,
             from: 'sets_enterprise_fee_set_collection_attributes_0_enterprise_id'
      select 'Packing', from: 'sets_enterprise_fee_set_collection_attributes_0_fee_type'
      fill_in 'sets_enterprise_fee_set_collection_attributes_0_name', with: 'foo'
      select 'GST', from: 'sets_enterprise_fee_set_collection_attributes_0_tax_category_id'
      select 'Flat Percent', from: 'sets_enterprise_fee_set_collection_attributes_0_calculator_type'
      click_button 'Update'

      expect(flash_message).to eq('Your enterprise fees have been updated.')

      # After saving, we should be redirected to the fees for our chosen enterprise
      expect(page).not_to have_select 'sets_enterprise_fee_set_collection_attributes_1_enterprise_id',
                                      selected: 'Second Distributor'

      enterprise_fee = EnterpriseFee.find_by name: 'foo'
      expect(enterprise_fee.enterprise).to eq(distributor1)
    end

    it "shows me only enterprise fees for the enterprise I select" do
      ef1
      ef2

      visit edit_admin_enterprise_path(distributor1)
      within(".side_menu") { click_link 'Enterprise Fees' }
      click_link "Manage Enterprise Fees"
      expect(page).to     have_field 'sets_enterprise_fee_set_collection_attributes_0_name',
                                     with: 'One'
      expect(page).not_to have_field 'sets_enterprise_fee_set_collection_attributes_1_name',
                                     with: 'Two'

      visit edit_admin_enterprise_path(distributor2)
      within(".side_menu") { click_link 'Enterprise Fees' }
      click_link "Manage Enterprise Fees"
      expect(page).not_to have_field 'sets_enterprise_fee_set_collection_attributes_0_name',
                                     with: 'One'
      expect(page).to     have_field 'sets_enterprise_fee_set_collection_attributes_0_name',
                                     with: 'Two'
    end

    it "only allows me to select enterprises I have access to" do
      ef1
      ef2
      distributor3

      visit edit_admin_enterprise_path(distributor2)
      within(".side_menu") { click_link 'Enterprise Fees' }
      click_link "Manage Enterprise Fees"
      expect(page).to have_select('sets_enterprise_fee_set_collection_attributes_0_enterprise_id',
                                  selected: 'Second Distributor',
                                  options: ['', 'First Distributor', 'Second Distributor'])
    end
  end
end
