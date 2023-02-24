# frozen_string_literal: true

require 'system_helper'

describe '
  As an Administrator
  I want to manage relationships between users and enterprises
' do
  include AuthenticationHelper
  include WebHelper
  include OpenFoodNetwork::EmailHelper

  context "as a site administrator" do
    before { login_to_admin_section }

    it "listing relationships" do
      # Given some users and enterprises with relationships
      u1, u2 = create(:user), create(:user)
      e1, e2, e3, e4 = create(:enterprise), create(:enterprise), create(:enterprise),
create(:enterprise)
      create(:enterprise_role, user: u1, enterprise: e1)
      create(:enterprise_role, user: u1, enterprise: e2)
      create(:enterprise_role, user: u2, enterprise: e3)
      create(:enterprise_role, user: u2, enterprise: e4)

      # When I go to the roles page
      click_link 'Users'
      click_link 'Roles'

      # Then I should see the relationships
      within('table#enterprise-roles') do
        expect(page).to have_relationship u1, e1
        expect(page).to have_relationship u1, e2
        expect(page).to have_relationship u2, e3
        expect(page).to have_relationship u2, e4
      end
    end

    it "creating a relationship" do
      u = create(:user, email: 'u@example.com')
      e = create(:enterprise, name: 'One')

      visit admin_enterprise_roles_path
      select 'u@example.com', from: 'enterprise_role_user_id'
      select 'One', from: 'enterprise_role_enterprise_id'
      click_button 'Create'

      # Wait for row to appear since have_relationship doesn't wait
      expect(page).to have_selector 'tr', count: 3
      expect(page).to have_relationship u, e
      expect(EnterpriseRole.where(user_id: u, enterprise_id: e)).to be_present
    end

    it "attempting to create a relationship with invalid data" do
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
        expect(page).to have_content "That role is already present."
      end.to change(EnterpriseRole, :count).by(0)
    end

    it "deleting a relationship" do
      u = create(:user, email: 'u@example.com')
      e = create(:enterprise, name: 'One')
      er = create(:enterprise_role, user: u, enterprise: e)

      visit admin_enterprise_roles_path
      expect(page).to have_relationship u, e

      within("#enterprise_role_#{er.id}") do
        accept_alert do
          find("a.delete-enterprise-role").click
        end
      end

      # Wait for row to disappear, otherwise have_relationship waits 30 seconds.
      expect(page).not_to have_selector "#enterprise_role_#{er.id}"
      expect(page).not_to have_relationship u, e
      expect(EnterpriseRole.where(id: er.id)).to be_empty
    end

    describe "using the enterprise managers interface" do
      let!(:user1) { create(:user, email: 'user1@example.com') }
      let!(:user2) { create(:user, email: 'user2@example.com') }
      let!(:user3) { create(:user, email: 'user3@example.com', confirmed_at: nil) }
      let(:new_email) { 'new@manager.com' }

      let!(:enterprise) { create(:enterprise, name: 'Test Enterprise', owner: user1) }
      let!(:enterprise_role) {
        create(:enterprise_role, user_id: user2.id, enterprise_id: enterprise.id)
      }

      before do
        click_link 'Enterprises'
        click_link 'Test Enterprise'
        navigate_to_enterprise_users
        expect(page).to have_selector "table.managers"
      end

      it "lists managers and shows icons for owner, contact, and email confirmation" do
        within 'table.managers' do
          expect(page).to have_content user1.email
          expect(page).to have_content user2.email

          within "tr#manager-#{user1.id}" do
            # user1 is both the enterprise owner and contact, and has email confirmed
            expect(page).to have_css 'i.owner'
            expect(page).to have_css 'i.contact'
            expect(page).to have_css 'i.confirmed'
          end
        end
      end

      xit "allows adding new managers" do
        within 'table.managers' do
          select2_select user3.email, from: 'ignored', search: true

          # user3 has been added and has an unconfirmed email address
          expect(page).to have_css "tr#manager-#{user3.id}"
          within "tr#manager-#{user3.id}" do
            expect(page).to have_css 'i.unconfirmed'
          end
        end
      end

      xit "shows changes to enterprise contact or owner" do
        select2_select user2.email, from: 'receives_notifications_dropdown'
        within('#save-bar') { click_button 'Update' }
        navigate_to_enterprise_users
        expect(page).to have_selector "table.managers"

        within 'table.managers' do
          within "tr#manager-#{user1.id}" do
            expect(page).to have_css 'i.owner'
            expect(page).to have_no_css 'i.contact'
          end
          within "tr#manager-#{user2.id}" do
            expect(page).to have_css 'i.contact'
          end
        end
      end

      xit "can invite unregistered users to be managers" do
        setup_email
        find('a.button.help-modal').click
        expect(page).to have_css '#invite-manager-modal'

        within '#invite-manager-modal' do
          fill_in 'invite_email', with: new_email
          click_button 'Invite'
          expect(page).to have_content "#{new_email} has been invited to manage this enterprise"
          click_button 'Close'
        end

        expect(page).not_to have_selector "#invite-manager-modal"
        expect(page).to have_selector "table.managers"

        new_user = Spree::User.find_by(email: new_email, confirmed_at: nil)
        expect(Enterprise.managed_by(new_user)).to include enterprise

        within 'table.managers' do
          expect(page).to have_content new_email

          within "tr#manager-#{new_user.id}" do
            expect(page).to have_css 'i.unconfirmed'
          end
        end
      end
    end
  end

  private

  def navigate_to_enterprise_users
    within ".side_menu" do
      click_link "Users"
    end
  end

  def have_relationship(user, enterprise)
    have_table_row [user.email, 'manages', enterprise.name, '']
  end
end
