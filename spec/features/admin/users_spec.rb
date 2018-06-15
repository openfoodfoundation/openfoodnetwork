require "spec_helper"

feature "Managing users" do
  include AuthenticationWorkflow

  context "as super-admin" do
    before { quick_login_as_admin }

    describe "creating a user" do
      it "works" do
        visit spree.new_admin_user_path
        fill_in "Email", with: "user1@example.org"
        fill_in "Password", with: "user1Secret"
        fill_in "Confirm Password", with: "user1Secret"
        expect do
          click_button "Create"
        end.to change { Spree::User.count }.by 1
        expect(page).to have_text "Created Successfully"
      end
    end
  end
end
