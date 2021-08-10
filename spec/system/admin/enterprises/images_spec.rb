# frozen_string_literal: true

require "spec_helper"

feature "Managing enterprise images" do
  include WebHelper
  include AuthenticationHelper

  context "as an Enterprise user", js: true do
    let(:enterprise_user) { create(:user, enterprise_limit: 1) }
    let(:distributor) { create(:distributor_enterprise, name: "First Distributor") }

    before do
      enterprise_user.enterprise_roles.build(enterprise: distributor).save!

      login_as enterprise_user
      visit edit_admin_enterprise_path(distributor)
    end

    describe "images for an enterprise" do
      def go_to_images
        within(".side_menu") do
          click_link "Images"
        end
      end

      before do
        go_to_images
      end

      scenario "editing logo" do
        # Adding image
        attach_file "enterprise[logo]", Rails.root.join("app", "assets", "images", "logo-white.png")
        click_button "Update"

        expect(page).to have_content("Enterprise \"#{distributor.name}\" has been successfully updated!")

        go_to_images
        within ".page-admin-enterprises-form__logo-field-group" do
          expect_preview_image "logo-white.png"
        end

        # Replacing image
        attach_file "enterprise[logo]", Rails.root.join("app", "assets", "images", "logo-black.png")
        click_button "Update"

        expect(page).to have_content("Enterprise \"#{distributor.name}\" has been successfully updated!")

        go_to_images
        within ".page-admin-enterprises-form__logo-field-group" do
          expect_preview_image "logo-black.png"
        end

        # Removing image
        within ".page-admin-enterprises-form__logo-field-group" do
          click_on "Remove Image"
          accept_js_alert
        end

        expect(page).to have_content("Logo removed successfully")

        within ".page-admin-enterprises-form__logo-field-group" do
          expect_no_preview_image
        end
      end

      scenario "editing promo image" do
        # Adding image
        attach_file "enterprise[promo_image]",
                    Rails.root.join("app", "assets", "images", "logo-white.png")
        click_button "Update"

        expect(page).to have_content("Enterprise \"#{distributor.name}\" has been successfully updated!")

        go_to_images
        within ".page-admin-enterprises-form__promo-image-field-group" do
          expect_preview_image "logo-white.jpg"
        end

        # Replacing image
        attach_file "enterprise[promo_image]",
                    Rails.root.join("app", "assets", "images", "logo-black.png")
        click_button "Update"

        expect(page).to have_content("Enterprise \"#{distributor.name}\" has been successfully updated!")

        go_to_images
        within ".page-admin-enterprises-form__promo-image-field-group" do
          expect_preview_image "logo-black.jpg"
        end

        # Removing image
        within ".page-admin-enterprises-form__promo-image-field-group" do
          click_on "Remove Image"
          accept_js_alert
        end

        expect(page).to have_content("Promo image removed successfully")

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
    expect(page).to have_no_selector(".image-field-group__preview-image")
  end
end
