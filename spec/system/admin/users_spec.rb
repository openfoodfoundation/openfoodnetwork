# frozen_string_literal: true

require "system_helper"

describe "Managing users" do
  include AuthenticationHelper
  include OpenFoodNetwork::EmailHelper

  context "as super-admin" do
    before do
      setup_email
      login_as_admin
    end

    context "from the index page" do
      before do
        create(:user, email: "a@example.com")
        create(:user, email: "b@example.com")

        visit spree.admin_dashboard_path
        click_link "Users"
      end

      context "users index page with sorting" do
        before(:each) do
          click_link "users_email_title"
        end

        it "should list users with order email asc" do
          expect(page).to have_css('table#listing_users')
          within("table#listing_users") do
            expect(page).to have_content("a@example.com")
            expect(page).to have_content("b@example.com")
          end
        end

        it "should list users with order email desc" do
          click_link "users_email_title"
          within("table#listing_users") do
            expect(page).to have_content("a@example.com")
            expect(page).to have_content("b@example.com")
          end
        end
      end

      context "searching users" do
        it "should display the correct results for a user search" do
          fill_in "q_email_cont", with: "a@example"
          click_button "Search"
          within("table#listing_users") do
            expect(page).to have_content("a@example")
            expect(page).not_to have_content("b@example")
          end
        end
      end

      context "editing users" do
        before(:each) do
          click_link("a@example.com")
        end

        it "should allow editing the user password" do
          fill_in "user_password", with: "welcome"
          fill_in "user_password_confirmation", with: "welcome"
          click_button "Update"

          expect(page).to have_content("Account updated")
        end

        it "should let me edit the user email" do
          fill_in "Email", with: "newemail@example.org"
          click_button "Update"

          expect(page).to have_content("The account will be updated once the new email is confirmed.")
        end

        it "should allow to generate, regenarate and clear the user api key" do
          user = Spree::User.find_by(email: "a@example.com")
          expect(page).to have_content "NO KEY"

          click_button "Generate API key"
          first_user_api_key = user.reload.spree_api_key
          expect(page).to have_content first_user_api_key

          click_button "Regenerate Key"
          second_user_api_key = user.reload.spree_api_key
          expect(page).to have_content second_user_api_key
          expect(second_user_api_key).not_to eq first_user_api_key

          click_button "Clear key"
          expect(page).to have_content "NO KEY"
        end

        it "should allow to disable the user and to enable it" do
          expect(page).to have_unchecked_field "Disabled"
          check "Disabled"
          click_button "Update"

          expect(page).to have_content("Account updated")
          expect(page).to have_checked_field "Disabled"
          uncheck "Disabled"
          click_button "Update"

          expect(page).to have_content("Account updated")
          expect(page).to have_unchecked_field "Disabled"
        end

        it "should toggle the api key generation view" do
          user = Spree::User.find_by(email: "a@example.com")

          expect(page).to have_content "NO KEY"
          expect {
            click_button("Generate API key")
            expect(page).to have_content("Key generated")
          }.to change { user.reload.spree_api_key }.from(nil)

          expect(page).to have_unchecked_field "Show API key view for user"

          expect {
            check "Show API key view for user"
            expect(page).to have_content("Show API key view has been changed!")
            expect(page).to have_checked_field "Show API key view for user"
          }.to change { user.reload.show_api_key_view }.from(false).to(true)

          expect {
            uncheck "Show API key view for user"
            expect(page).to have_content("Show API key view has been changed!")
            expect(page).to have_unchecked_field "Show API key view for user"
          }.to change { user.reload.show_api_key_view }.to(false)
        end
      end
    end

    describe "creating a user" do
      it "shows no confirmation message to start with" do
        visit spree.new_admin_user_path
        expect(page).to have_no_text "Email confirmation is pending"
      end

      it "confirms successful creation" do
        visit spree.new_admin_user_path
        fill_in "Email", with: "user1@example.org"
        fill_in "Password", with: "user1Secret"
        fill_in "Confirm Password", with: "user1Secret"
        expect do
          click_button "Create"
        end.to change { Spree::User.count }.by 1
        expect(page).to have_text "Created Successfully"
        expect(page).to have_text "Email confirmation is pending"
      end
    end

    describe "resending confirmation email" do
      let(:user) { create :user, confirmed_at: nil }

      around do |example|
        performing_deliveries { example.run }
      end

      it "displays success" do
        visit spree.edit_admin_user_path user

        expect do
          # The `a` element doesn't have an href, so we can't use click_link.
          find("a", text: "Resend").click
          expect(page).to have_text "Resend done"
        end.to enqueue_job ActionMailer::MailDeliveryJob
      end
    end
  end
end
