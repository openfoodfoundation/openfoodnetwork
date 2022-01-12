# frozen_string_literal: true

require 'system_helper'

describe '
    As an administrator
    I want to manage enterprise groups
' do
  include WebHelper
  include AuthenticationHelper

  before(:each) do
    login_to_admin_section
  end

  it "listing enterprise groups" do
    e = create(:enterprise)
    group = create(:enterprise_group, enterprises: [e], on_front_page: true)

    click_link 'Groups'

    expect(page).to have_selector 'td', text: group.name
    expect(page).to have_selector 'td', text: 'Y'
    expect(page).to have_selector 'td', text: e.name
  end

  it "creating a new enterprise group" do
    e1 = create(:enterprise)
    e2 = create(:enterprise)
    e3 = create(:enterprise)

    click_link 'Groups'
    click_link 'New Enterprise Group'

    fill_in 'enterprise_group_name', with: 'EGEGEG'
    fill_in 'enterprise_group_description', with: 'This is a description'
    check 'enterprise_group_on_front_page'
    select2_select e1.name, from: 'enterprise_group_enterprise_ids', search: true
    select2_select e2.name, from: 'enterprise_group_enterprise_ids', search: true
    click_link 'Contact'
    fill_in 'enterprise_group_address_attributes_phone', with: '000'
    fill_in 'enterprise_group_address_attributes_address1', with: 'My Street'
    fill_in 'enterprise_group_address_attributes_city', with: 'Block'
    fill_in 'enterprise_group_address_attributes_zipcode', with: '0000'
    select2_select 'Australia', from: 'enterprise_group_address_attributes_country_id'
    select2_select 'Victoria', from: 'enterprise_group_address_attributes_state_id'
    click_button 'Create'

    expect(page).to have_content 'Enterprise group "EGEGEG" has been successfully created!'

    eg = EnterpriseGroup.last
    expect(eg.name).to eq('EGEGEG')
    expect(eg.description).to eq('This is a description')
    expect(eg.on_front_page).to be true
    expect(eg.enterprises).to match_array [e1, e2]
  end

  it "editing an enterprise group" do
    e1 = create(:enterprise)
    e2 = create(:enterprise)
    eg = create(:enterprise_group, name: 'EGEGEG', on_front_page: true, enterprises: [e1, e2])

    click_link 'Groups'
    first("a.edit-enterprise-group").click

    expect(page).to have_field 'enterprise_group_name', with: 'EGEGEG'
    expect(page).to have_checked_field 'enterprise_group_on_front_page'
    expect(page).to have_select 'enterprise_group_enterprise_ids', selected: [e1.name, e2.name]

    fill_in 'enterprise_group_name', with: 'xyzzy'
    uncheck 'enterprise_group_on_front_page'
    unselect e1.name, from: 'enterprise_group_enterprise_ids'

    select e2.name, from: 'enterprise_group_enterprise_ids'
    click_button 'Update'

    expect(page).to have_content 'Enterprise group "xyzzy" has been successfully updated!'

    eg = EnterpriseGroup.last
    expect(eg.name).to eq('xyzzy')
    expect(eg.on_front_page).to be false
    expect(eg.enterprises).to eq([e2])
  end

  it "re-ordering enterprise groups" do
    eg1 = create(:enterprise_group, name: 'A')
    eg2 = create(:enterprise_group, name: 'B')

    click_link 'Groups'

    expect(page.all('td.name').map(&:text)).to eq(['A', 'B'])
    all("a.move-down").first.click
    expect(page.all('td.name').map(&:text)).to eq(['B', 'A'])
    all("a.move-up").last.click
    expect(page.all('td.name').map(&:text)).to eq(['A', 'B'])
  end

  it "deleting an enterprise group" do
    eg = create(:enterprise_group, name: 'EGEGEG')

    click_link 'Groups'
    accept_alert do
      first("a.delete-resource").click
    end

    expect(page).to have_no_content 'EGEGEG'

    expect(EnterpriseGroup.all).not_to include eg
  end

  context "as an enterprise user" do
    let(:user) { create(:user) }
    let!(:enterprise) { create(:distributor_enterprise, owner: user) }
    let!(:group) { create(:enterprise_group, name: 'My Group', owner: user) }

    it "lets me access enterprise groups" do
      login_as user
      visit spree.admin_dashboard_path
      click_link 'Groups'
      expect(page).to have_content 'My Group'
    end
  end
end
