# frozen_string_literal: true

require "system_helper"

describe "Uploading Terms and Conditions PDF" do
  include AuthenticationHelper
  include FileHelper

  context "as an Enterprise user" do
    let(:enterprise_user) { create(:user, enterprise_limit: 1) }
    let(:distributor) { create(:distributor_enterprise, name: "First Distributor") }

    before do
      enterprise_user.enterprise_roles.build(enterprise: distributor).save!

      login_as enterprise_user
      visit edit_admin_enterprise_path(distributor)
    end

    describe "with terms and conditions to upload" do
      def go_to_business_details
        within(".side_menu") do
          click_link "Business Details"
        end
      end

      let(:original_terms) { Rails.root.join("public/Terms-of-service.pdf") }
      let(:updated_terms) { Rails.root.join("public/Terms-of-ServiceUK.pdf") }

      it "uploading terms and conditions" do
        go_to_business_details

        # Add PDF
        attach_file "enterprise[terms_and_conditions]", original_terms

        time = Time.zone.local(2002, 4, 13, 0, 0, 0)
        Timecop.freeze(run_time = time) do
          click_button "Update"
          expect(distributor.reload.terms_and_conditions_blob.created_at).to eq run_time
        end
        expect(page).
          to have_content "Enterprise \"#{distributor.name}\" has been successfully updated!"

        go_to_business_details
        expect(page).to have_selector "a[href*='Terms-of-service.pdf'][target=\"_blank\"]"
        expect(page).to have_content time.strftime("%F %T")

        # Replace PDF
        attach_file "enterprise[terms_and_conditions]", updated_terms
        click_button "Update"
        expect(page).
          to have_content "Enterprise \"#{distributor.name}\" has been successfully updated!"
        expect(distributor.reload.terms_and_conditions_blob.created_at).to_not eq run_time

        go_to_business_details
        expect(page).to have_selector "a[href*='Terms-of-ServiceUK.pdf']"
      end
    end
  end
end
