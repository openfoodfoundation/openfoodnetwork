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

end
