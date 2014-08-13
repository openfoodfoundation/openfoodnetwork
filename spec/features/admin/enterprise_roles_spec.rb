require 'spec_helper'

feature %q{
  As an Administrator
  I want to manage relationships between users and enterprises
}, js: true do
  include AuthenticationWorkflow
  include WebHelper


  context "as a site administrator" do
    before { login_to_admin_section }

    scenario "listing relationships" do
      # Given some users and enterprises with relationships
      u1, u2 = create(:user), create(:user)
      e1, e2, e3, e4 = create(:enterprise), create(:enterprise), create(:enterprise), create(:enterprise)
      create(:enterprise_role, user: u1, enterprise: e1)
      create(:enterprise_role, user: u1, enterprise: e2)
      create(:enterprise_role, user: u2, enterprise: e3)
      create(:enterprise_role, user: u2, enterprise: e4)

      # When I go to the roles page
      click_link 'Users'
      click_link 'Roles'

      # Then I should see the relationships
      within('table#enterprise-roles') do
        page.should have_relationship u1, e1
        page.should have_relationship u1, e2
        page.should have_relationship u2, e3
        page.should have_relationship u2, e4
      end
    end
  end


  private

  def have_relationship(user, enterprise)
    have_table_row [user.email, 'manages', enterprise.name, '']
  end
end
