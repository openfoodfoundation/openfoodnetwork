# frozen_string_literal: true

require 'system_helper'

describe '
    As an administrator
    I want to manage enterprise fees
' do
  include WebHelper
  include AuthenticationHelper

  let!(:tax_category_gst) { create(:tax_category, name: 'GST') }

  it "listing enterprise fees" do
    fee = create(:enterprise_fee, name: '$0.50 / kg', fee_type: 'packing',
                                  tax_category: tax_category_gst)
    amount = fee.calculator.preferred_amount

    login_as_admin
    visit spree.edit_admin_general_settings_path
    click_link 'Enterprise Fees'

    expect(page).to have_select "#{prefix}_enterprise_id"
    expect(page).to have_select "#{prefix}_fee_type", selected: 'Packing fee'
    expect(page).to have_selector "input[value='$0.50 / kg']"
    expect(page).to have_select "#{prefix}_tax_category_id", selected: 'GST'
    expect(page).to have_select "#{prefix}_calculator_type", selected: 'Flat Rate (per item)'
    expect(page).to have_selector "input[value='#{amount}']"
  end

  it "creating an enterprise fee" do
    # Given an enterprise
    e = create(:supplier_enterprise, name: 'Feedme')

    # When I go to the enterprise fees page
    login_as_admin
    visit admin_enterprise_fees_path

    # And I fill in the fields for a new enterprise fee and click update
    select 'Feedme', from: "#{prefix}_enterprise_id"
    select 'Admin', from: "#{prefix}_fee_type"
    fill_in "#{prefix}_name", with: 'Hello!'
    select 'GST', from: "#{prefix}_tax_category_id"
    select 'Flat Percent', from: "#{prefix}_calculator_type"
    click_button 'Update'

    # Then I should see my fee and fields for the calculator
    expect(page).to have_content "Your enterprise fees have been updated."
    expect(page).to have_selector "input[value='Hello!']"

    # When I fill in the calculator fields and click update
    fill_in "#{prefix}_calculator_attributes" \
            "_preferred_flat_percent", with: '12.34'
    click_button 'Update'

    # Then I should see the correct values in my calculator fields
    expect(page).to have_selector("##{prefix}_calculator" \
                                  "_attributes_preferred_flat_percent[value='12.34']")
  end

  it "creating an enterprise fee with invalid amount shows error flash message" do
    # Given an enterprise
    e = create(:supplier_enterprise, name: 'Feedme')

    # When I go to the enterprise fees page
    login_as_admin
    visit admin_enterprise_fees_path

    # And I fill in the fields for a new enterprise fee and click update
    select 'Feedme', from: "#{prefix}_enterprise_id"
    select 'Admin', from: "#{prefix}_fee_type"
    fill_in "#{prefix}_name", with: 'Hello!'
    select 'GST', from: "#{prefix}_tax_category_id"
    select 'Flat Percent', from: "#{prefix}_calculator_type"
    click_button 'Update'

    # Then I should see my fee and fields for the calculator
    expect(page).to have_content "Your enterprise fees have been updated."
    expect(page).to have_selector "input[value='Hello!']"

    # When I fill in the calculator fields and click update
    fill_in("#{prefix}_calculator_attributes_preferred_flat_percent", with: "\'20.0'")
    click_button 'Update'

    # Then I should see the flash error message
    expect(flash_message).to eq('Invalid input. Please use only numbers. For example: 10, 5.5, -20')
  end

  context "editing an enterprise fee" do
    # Given an enterprise fee
    let!(:fee) { create(:enterprise_fee) }
    let!(:enterprise) { create(:enterprise, name: 'Foo') }

    before do
      # When I go to the enterprise fees page
      login_as_admin
      visit admin_enterprise_fees_path
      # And I update the fields for the enterprise fee and click update
      select 'Foo', from: "#{prefix}_enterprise_id"
      select 'Admin', from: "#{prefix}_fee_type"
      fill_in "#{prefix}_name", with: 'Greetings!'
      select 'Inherit From Product', from: "#{prefix}_tax_category_id"
      select 'Flat Percent', from: "#{prefix}_calculator_type"
      click_button 'Update'
    end

    it "handle the default cases" do
      # Then I should see the updated fields for my fee
      expect(page).to have_select "#{prefix}_enterprise_id", selected: 'Foo'
      expect(page).to have_select "#{prefix}_fee_type", selected: 'Admin fee'
      expect(page).to have_selector "input[value='Greetings!']"
      expect(page).to have_select "#{prefix}_tax_category_id", selected: 'Inherit From Product'
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

    it "handle when updating calculator type for Weight to Flat Rate" do
      select 'Weight (per kg or lb)', from: "#{prefix}_calculator_type"
      click_button 'Update'

      select 'Flat Rate (per item)', from: "#{prefix}_calculator_type"
      click_button 'Update'

      expect(fee.reload.calculator_type).to eq("Calculator::PerItem")
    end

    it 'shows error flash when updating fee amount with invalid values' do
      # When I fill in the calculator fields and click update
      fill_in(
        "#{prefix}_calculator_attributes_" \
        'preferred_flat_percent', with: "\'20.0'"
      )
      click_button 'Update'

      # Then I should see the flash error message
      expect(flash_message)
        .to eq('Invalid input. Please use only numbers. For example: 10, 5.5, -20')
    end

    it "does not allow editing to an invalid combination" do
      # starting with a valid tax category / calculator combination
      expect(page).to have_select "#{prefix}_tax_category_id", selected: 'Inherit From Product'
      expect(page).to have_selector "option[selected]", text: 'Flat Percent (per item)'

      # editing to an invalid combination
      select 'Flat Rate (per order)', from: "#{prefix}_calculator_type"
      expect{ click_button 'Update' }.to_not change { fee.reload.calculator_type }
      expect(page).to have_content "Inheriting the tax categeory requires a per-item calculator."
    end

    context "editing two enterprise fees" do
      let!(:fee1) { create(:enterprise_fee, fee_type: "sales", enterprise_id: enterprise.id) }

      before do
        # edits the existing fee
        select 'Fundraising', from: "#{prefix}_fee_type"
        fill_in "#{prefix}_name", with: 'Hello!'

        # edits the another fee
        select 'Sales', from: "#{prefix1}_fee_type"
        fill_in "#{prefix1}_name", with: 'World!'
        select 'GST', from: "#{prefix1}_tax_category_id"
        select 'Flat Rate', from: "#{prefix1}_calculator_type"
        click_button 'Update'

        # edits the mounts on the calculators
        fill_in "#{prefix}_calculator_attributes_preferred_flat_percent", with: 12.5
        fill_in "#{prefix1}_calculator_attributes_preferred_amount", with: 1.5
        click_button 'Update'
      end

      it "handles updating two enterprise fees" do
        # Then I should see the updated fields for my fees
        expect(page).to have_select "#{prefix}_fee_type", selected: 'Fundraising fee'
        expect(page).to have_selector "input[value='Hello!']"
        expect(page).to have_select "#{prefix}_tax_category_id", selected: 'Inherit From Product'
        expect(page).to have_selector "option[selected]", text: 'Flat Percent (per item)'
        expect(page).to have_field "Flat Percent:", with: '12.5'

        expect(page).to have_select "#{prefix1}_enterprise_id", selected: 'Foo'
        expect(page).to have_select "#{prefix1}_fee_type", selected: 'Sales fee'
        expect(page).to have_selector "input[value='World!']"
        expect(page).to have_select "#{prefix1}_tax_category_id", selected: 'GST'
        expect(page).to have_selector "option[selected]", text: 'Flat Rate (per order)'
        expect(page).to have_field "Amount:", with: '1.5'

        fee.reload
        expect(fee.enterprise).to eq(enterprise)
        expect(fee.name).to eq('Hello!')
        expect(fee.fee_type).to eq('fundraising')
        expect(fee.calculator_type).to eq("Calculator::FlatPercentPerItem")

        fee1.reload
        expect(fee1.enterprise).to eq(enterprise)
        expect(fee1.name).to eq('World!')
        expect(fee1.fee_type).to eq('sales')
        expect(fee1.calculator_type).to eq("Calculator::FlatRate")

        # Sets tax_category and inherits_tax_category
        expect(fee.tax_category).to eq(nil)
        expect(fee.inherits_tax_category).to eq(true)

        # Sets tax_category and inherits_tax_category
        expect(fee1.tax_category).to eq(tax_category_gst)
        expect(fee1.inherits_tax_category).to eq(false)
      end
    end
  end

  it "deleting an enterprise fee" do
    # Given an enterprise fee
    fee = create(:enterprise_fee)

    # When I go to the enterprise fees page
    login_as_admin
    visit admin_enterprise_fees_path

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

    context "creating an enterprise fee" do
      before do
        visit edit_admin_enterprise_path(distributor1)
        within(".side_menu") { click_link 'Enterprise Fees' }
        click_link "Create One Now"
      end

      shared_examples "setting it up" do |tax_category, calculator, flash_message, fee_count|
        context "as #{tax_category}, with a #{calculator} calculator" do
          it "triggers the expected message" do
            select distributor1.name, from: "#{prefix}_enterprise_id"
            select 'Packing', from: "#{prefix}_fee_type"
            fill_in "#{prefix}_name", with: 'foo'
            select tax_category, from: "#{prefix}_tax_category_id"
            select calculator, from: "#{prefix}_calculator_type"
            click_button 'Update'

            # The correct flash message should be displayed
            expect(page).to have_content(flash_message)

            # After saving, we should be redirected to the fees for our chosen enterprise
            expect(page).
              not_to have_select 'sets_enterprise_fee_set_collection_attributes_1_enterprise_id',
                                 selected: 'Second Distributor'

            # A new enterprise fee is created
            expect(EnterpriseFee.count).to eq(fee_count)
          end
        end
      end

      context "an error message is displayed" do
        message = 'Inheriting the tax categeory requires a per-item calculator.'
        it_behaves_like "setting it up", 'Inherit From Product',
                        'Flat Rate (per order)', message, 0
      end

      context "an success message is displayed" do
        message = 'Your enterprise fees have been updated.'
        it_behaves_like "setting it up", 'Inherit From Product', 'Flat Rate (per item)', message, 1
      end

      context "an success message is displayed" do
        message = 'Your enterprise fees have been updated.'
        it_behaves_like "setting it up", 'GST', 'Flat Rate (per order)', message, 1
      end

      context "an success message is displayed" do
        message = 'Your enterprise fees have been updated.'
        it_behaves_like "setting it up", 'GST', 'Flat Rate (per item)', message, 1
      end
    end

    it "shows me only enterprise fees for the enterprise I select" do
      ef1
      ef2

      visit edit_admin_enterprise_path(distributor1)
      within(".side_menu") { click_link 'Enterprise Fees' }
      click_link "Manage Enterprise Fees"
      expect(page).to     have_field "#{prefix}_name", with: 'One'
      expect(page).not_to have_field 'sets_enterprise_fee_set_collection_attributes_1_name',
                                     with: 'Two'

      visit edit_admin_enterprise_path(distributor2)
      within(".side_menu") { click_link 'Enterprise Fees' }
      click_link "Manage Enterprise Fees"
      expect(page).not_to have_field "#{prefix}_name", with: 'One'
      expect(page).to     have_field "#{prefix}_name", with: 'Two'
    end

    it "only allows me to select enterprises I have access to" do
      ef1
      ef2
      distributor3

      visit edit_admin_enterprise_path(distributor2)
      within(".side_menu") { click_link 'Enterprise Fees' }
      click_link "Manage Enterprise Fees"
      expect(page).to have_select("#{prefix}_enterprise_id",
                                  selected: 'Second Distributor',
                                  options: ['First Distributor', 'Second Distributor'])
    end
  end
end

def prefix
  'sets_enterprise_fee_set_collection_attributes_0'
end

def prefix1
  'sets_enterprise_fee_set_collection_attributes_1'
end
