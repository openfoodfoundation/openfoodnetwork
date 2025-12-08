# frozen_string_literal: true

require "system_helper"

RSpec.describe "Managing enterprise images" do
  include WebHelper
  include FileHelper
  include AuthenticationHelper

  context "as an Enterprise user" do
    let(:enterprise_user) { create(:user, enterprise_limit: 1) }
    let(:distributor) { create(:distributor_enterprise, name: "First Distributor") }

    before do
      enterprise_user.enterprise_roles.build(enterprise: distributor).save!

      login_as enterprise_user
      visit edit_admin_enterprise_path(distributor)
    end

    describe "images for an enterprise" do
      let(:alert_text_logo) { 'The logo will be removed immediately after you confirm'.strip }
      let(:alert_text_promo) {
        'The promo image will be removed immediately after you confirm.'.strip
      }

      def go_to_images
        within(".side_menu") do
          click_link "Images"
        end
      end

      before do
        go_to_images
      end

      it "editing logo" do
        # Adding image
        attach_file "enterprise[logo]", white_logo_path
        click_button "Update"

        expect(page).to have_content(
          "Enterprise \"#{distributor.name}\" has been successfully updated!"
        )

        go_to_images
        within ".page-admin-enterprises-form__logo-field-group" do
          expect_preview_image "logo-white.png"
        end

        # Replacing image
        attach_file "enterprise[logo]", black_logo_path
        click_button "Update"

        expect(page).to have_content(
          "Enterprise \"#{distributor.name}\" has been successfully updated!"
        )

        go_to_images
        within ".page-admin-enterprises-form__logo-field-group" do
          expect_preview_image "logo-black.png"
        end

        # Removing image
        within ".page-admin-enterprises-form__logo-field-group" do
          click_button "Remove Image"
        end

        within ".reveal-modal" do
          expect(page).to have_content(alert_text_logo)
          click_button "Confirm"
        end

        # There's a race condition.
        # Either of these messages can be observed.
        expect(flash_message).to match /(Logo removed)|(Enterprise .* updated)/

        within ".page-admin-enterprises-form__logo-field-group" do
          expect_no_preview_image
        end
      end

      it "editing promo image" do
        # Adding image
        attach_file "enterprise[promo_image]", white_logo_path
        click_button "Update"

        expect(page).to have_content(
          "Enterprise \"#{distributor.name}\" has been successfully updated!"
        )

        go_to_images
        within ".page-admin-enterprises-form__promo-image-field-group" do
          expect_preview_image "logo-white.png"
        end

        # Replacing image
        attach_file "enterprise[promo_image]", black_logo_path
        click_button "Update"

        expect(page).to have_content(
          "Enterprise \"#{distributor.name}\" has been successfully updated!"
        )

        go_to_images
        within ".page-admin-enterprises-form__promo-image-field-group" do
          expect_preview_image "logo-black.png"
        end

        # Removing image
        within ".page-admin-enterprises-form__promo-image-field-group" do
          click_on "Remove Image"
        end

        within ".reveal-modal" do
          expect(page).to have_content(alert_text_promo)
          click_button "Confirm"
        end

        expect(page).to have_content("Promo image removed")

        within ".page-admin-enterprises-form__promo-image-field-group" do
          expect_no_preview_image
        end
      end
    end
  end

  def expect_preview_image(file_name)
    expect(page).to have_selector(".image-field-group__preview-image[src*='#{file_name}']")
  end

  def expect_no_preview_image
    expect(page).not_to have_selector(".image-field-group__preview-image")
  end
end
