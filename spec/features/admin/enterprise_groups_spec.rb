require 'spec_helper'

feature %q{
    As an administrator
    I want to manage enterprise groups
} do
  include AuthenticationWorkflow
  include WebHelper

  before(:each) do
    login_to_admin_section
  end

  scenario "listing enterprise groups" do
    e = create(:enterprise)
    group = create(:enterprise_group, enterprises: [e], on_front_page: true)

    click_link 'Configuration'
    click_link 'Enterprise Groups'

    page.should have_selector 'td', text: group.name
    page.should have_selector 'td', text: 'Y'
    page.should have_selector 'td', text: e.name
  end

  scenario "creating a new enterprise group" do
    e1 = create(:enterprise)
    e2 = create(:enterprise)
    e3 = create(:enterprise)

    click_link 'Configuration'
    click_link 'Enterprise Groups'
    click_link 'New Enterprise Group'

    fill_in 'enterprise_group_name', with: 'EGEGEG'
    check 'enterprise_group_on_front_page'
    select e1.name, from: 'enterprise_group_enterprise_ids'
    select e2.name, from: 'enterprise_group_enterprise_ids'
    click_button 'Create'

    page.should have_content 'Enterprise group "EGEGEG" has been successfully created!'

    eg = EnterpriseGroup.last
    eg.name.should == 'EGEGEG'
    eg.on_front_page.should be_true
    eg.enterprises.sort.should == [e1, e2].sort
  end

  scenario "editing an enterprise group" do
    e1 = create(:enterprise)
    e2 = create(:enterprise)
    eg = create(:enterprise_group, name: 'EGEGEG', on_front_page: true, enterprises: [e1, e2])

    click_link 'Configuration'
    click_link 'Enterprise Groups'
    first("a.edit-enterprise-group").click

    page.should have_field 'enterprise_group_name', with: 'EGEGEG'
    page.should have_checked_field 'enterprise_group_on_front_page'
    page.should have_select 'enterprise_group_enterprise_ids', selected: [e1.name, e2.name]

    fill_in 'enterprise_group_name', with: 'xyzzy'
    uncheck 'enterprise_group_on_front_page'
    unselect e1.name, from: 'enterprise_group_enterprise_ids'
    select e2.name, from: 'enterprise_group_enterprise_ids'
    click_button 'Update'

    page.should have_content 'Enterprise group "xyzzy" has been successfully updated!'

    eg = EnterpriseGroup.last
    eg.name.should == 'xyzzy'
    eg.on_front_page.should be_false
    eg.enterprises.should == [e2]
  end

  scenario "re-ordering enterprise groups" do
    eg1 = create(:enterprise_group, name: 'A')
    eg2 = create(:enterprise_group, name: 'B')

    click_link 'Configuration'
    click_link 'Enterprise Groups'

    page.all('td.name').map(&:text).should == ['A', 'B']
    all("a.move-down").first.click
    page.all('td.name').map(&:text).should == ['B', 'A']
    all("a.move-up").last.click
    page.all('td.name').map(&:text).should == ['A', 'B']
  end

  scenario "deleting an enterprise group", js: true do
    eg = create(:enterprise_group, name: 'EGEGEG')

    click_link 'Configuration'
    click_link 'Enterprise Groups'
    first("a.delete-resource").click

    page.should have_no_content 'EGEGEG'

    EnterpriseGroup.all.should_not include eg
  end


  context "as an enterprise user" do
    xit "should show me only enterprises I manage when creating a new enterprise group"
  end
end
