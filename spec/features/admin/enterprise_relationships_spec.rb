require 'spec_helper'

feature %q{
  As an Administrator
  I want to manage relationships between enterprises
}, js: true do
  include AuthenticationWorkflow
  include WebHelper

  before { login_to_admin_section }

  scenario "listing relationships" do
    # Given some enterprises with relationships
    e1, e2, e3, e4 = create(:enterprise), create(:enterprise), create(:enterprise), create(:enterprise)
    create(:enterprise_relationship, parent: e1, child: e2)
    create(:enterprise_relationship, parent: e3, child: e4)

    # When I go to the relationships page
    click_link 'Enterprises'
    click_link 'Relationships'

    # Then I should see the relationships
    within('table#enterprise-relationships') do
      page.should have_table_row [e1.name, e2.name]
      page.should have_table_row [e3.name, e4.name]
    end
  end


  scenario "creating a relationship"
  scenario "deleting a relationship"
end
