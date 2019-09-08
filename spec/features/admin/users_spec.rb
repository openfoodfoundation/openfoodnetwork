require "spec_helper"

feature "Managing users" do
  include AuthenticationWorkflow
  include OpenFoodNetwork::EmailHelper

  context "as super-admin" do
    before do
      setup_email
      quick_login_as_admin
    end

    context "from the index page" do
      before do
        create(:user, :email => "a@example.com")
        create(:user, :email => "b@example.com")

        visit spree.admin_path
        click_link "Users"
      end

      context "users index page with sorting" do
        before(:each) do
          click_link "users_email_title"
        end

        it "should be able to list users with order email asc" do
          expect(page).to have_css('table#listing_users')
          within("table#listing_users") do
            expect(page).to have_content("a@example.com")
            expect(page).to have_content("b@example.com")
          end
        end

        it "should be able to list users with order email desc" do
          click_link "users_email_title"
          within("table#listing_users") do
            expect(page).to have_content("a@example.com")
            expect(page).to have_content("b@example.com")
          end
        end
      end

      context "searching users" do
        it "should display the correct results for a user search" do
          fill_in "q_email_cont", :with => "a@example"
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

        it "should let me edit the user password" do
          fill_in "user_password", :with => "welcome"
          fill_in "user_password_confirmation", :with => "welcome"
          click_button "Update"

          expect(page).to have_content("Account updated")
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

    describe "resending confirmation email", js: true do
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
        end.to send_confirmation_instructions
      end
    end
  end
end
