# frozen_string_literal: true

require "spec_helper"

feature '
    As an admin
    I want to manage product properties
' do
  include AuthenticationHelper

  scenario "creating and editing a property" do
    login_as_admin_and_visit spree.admin_properties_path

    click_link 'New Property'
    fill_in 'property_name', with: 'New property!'
    fill_in 'property_presentation', with: 'New property presentation!'
    click_button 'Create'
    expect(page).to have_content 'New property!'

    page.find('td.actions a.icon-edit').click
    expect(page).to have_field 'property_name', with: 'New property!'
    fill_in 'property_name', with: 'New changed property!'
    click_button 'Update'
    expect(page).to have_content 'New changed property!'
  end
end
