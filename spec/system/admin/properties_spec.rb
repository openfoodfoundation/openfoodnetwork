# frozen_string_literal: true

require "system_helper"

describe '
    As an admin
    I want to manage product properties
' do
  include AuthenticationHelper

  it "creating and editing a property" do
    login_as_admin
    visit spree.admin_properties_path

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
