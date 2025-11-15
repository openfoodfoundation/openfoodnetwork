# frozen_string_literal: true

require "system_helper"

RSpec.describe "Managing users" do
  include AuthenticationHelper

  context "as super-admin" do
    before do
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

          expect(page).to have_content("The account will be updated once " \
                                       "the new email is confirmed.")
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

      context "pagination" do
        before do
          # creates 8 more users
          8.times { create(:user) }
          expect(Spree::User.count).to eq 11
          visit spree.admin_users_path
        end
        it "displays pagination" do
          # table displays 10 entries
          within('tbody') do
            expect(page).to have_css('tr', count: 10)
          end
          within ".pagination" do
            expect(page).not_to have_content "Previous"
            expect(page).to have_content "Next"
            click_on "2"
          end
          # table displays 1 entry
          within('tbody') do
            expect(page).to have_css('tr', count: 1)
          end
          within ".pagination" do
            expect(page).to have_content "Previous"
            expect(page).not_to have_content "Next"
          end
        end
      end
    end

    describe "creating a user" do
      it "confirms successful creation" do
        visit spree.new_admin_user_path

        # shows no confirmation message to start with
        expect(page).not_to have_text "Email confirmation is pending"

        fill_in "Email", with: "user1@example.org"
        fill_in "Password", with: "user1Secret"
        fill_in "Confirm Password", with: "user1Secret"

        expect(page).to have_select "Language", selected: "English"
        select "Español", from: "Language"

        perform_enqueued_jobs do
          expect do
            click_button "Create"
          end.to change { Spree::User.count }.by 1
          expect(page).to have_text "User has been successfully created!"
          expect(page).to have_text "Email confirmation is pending"

          expect(Spree::User.last.locale).to eq "es"

          expect(ActionMailer::Base.deliveries.first.subject).to match(
            "Por favor, confirma tu cuenta de OFN"
          )
        end
      end
    end

    describe "resending confirmation email" do
      let(:user) { create :user, confirmed_at: nil }

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
