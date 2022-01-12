# frozen_string_literal: true

require "system_helper"

describe "Uploading Terms and Conditions PDF" do
  include AuthenticationHelper
  include FileHelper

  context "as an Enterprise user", js: true do
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

      let(:white_pdf_file_name) { Rails.root.join("app/webpacker/images/logo-white.pdf") }
      let(:black_pdf_file_name) { Rails.root.join("app/webpacker/images/logo-black.pdf") }

      around do |example|
        # Create fake PDFs from PNG images
        FileUtils.cp(white_logo_path, white_pdf_file_name)
        FileUtils.cp(black_logo_path, black_pdf_file_name)

        example.run

        # Delete fake PDFs
        FileUtils.rm_f(white_pdf_file_name)
        FileUtils.rm_f(black_pdf_file_name)
      end

      it "uploading terms and conditions" do
        go_to_business_details

        # Add PDF
        attach_file "enterprise[terms_and_conditions]", white_pdf_file_name

        time = Time.zone.local(2002, 4, 13, 0, 0, 0)
        Timecop.freeze(run_time = time) do
          click_button "Update"
          expect(distributor.reload.terms_and_conditions_updated_at).to eq run_time
        end
        expect(page).
          to have_content "Enterprise \"#{distributor.name}\" has been successfully updated!"

        go_to_business_details
        expect(page).to have_selector "a[href*='logo-white.pdf'][target=\"_blank\"]"
        expect(page).to have_content time.strftime("%F %T")

        # Replace PDF
        attach_file "enterprise[terms_and_conditions]", black_pdf_file_name
        click_button "Update"
        expect(page).
          to have_content "Enterprise \"#{distributor.name}\" has been successfully updated!"
        expect(distributor.reload.terms_and_conditions_updated_at).to_not eq run_time

        go_to_business_details
        expect(page).to have_selector "a[href*='logo-black.pdf']"
      end
    end
  end
end
