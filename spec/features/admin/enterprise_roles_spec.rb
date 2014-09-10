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

    scenario "creating a relationship" do
      u = create(:user, email: 'u@example.com')
      e = create(:enterprise, name: 'One')

      visit admin_enterprise_roles_path
      select 'u@example.com', from: 'enterprise_role_user_id'
      select 'One', from: 'enterprise_role_enterprise_id'
      click_button 'Create'

      page.should have_relationship u, e
      EnterpriseRole.where(user_id: u, enterprise_id: e).should be_present
    end

    scenario "attempting to create a relationship with invalid data" do
      u = create(:user, email: 'u@example.com')
      e = create(:enterprise, name: 'One')
      create(:enterprise_role, user: u, enterprise: e)

      expect do
        # When I attempt to create a duplicate relationship
        visit admin_enterprise_roles_path
        select 'u@example.com', from: 'enterprise_role_user_id'
        select 'One', from: 'enterprise_role_enterprise_id'
        click_button 'Create'

        # Then I should see an error message
        page.should have_content "That role is already present."
      end.to change(EnterpriseRole, :count).by(0)
    end

    scenario "deleting a relationship" do
      u = create(:user, email: 'u@example.com')
      e = create(:enterprise, name: 'One')
      er = create(:enterprise_role, user: u, enterprise: e)

      visit admin_enterprise_roles_path
      page.should have_relationship u, e

      within("#enterprise_role_#{er.id}") do
        find("a.delete-enterprise-role").click
      end

      page.should_not have_relationship u, e
      EnterpriseRole.where(id: er.id).should be_empty
    end
  end


  private

  def have_relationship(user, enterprise)
    have_table_row [user.email, 'manages', enterprise.name, '']
  end
end
