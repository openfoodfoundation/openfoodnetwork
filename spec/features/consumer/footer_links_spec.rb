require 'spec_helper'

feature "Footer Links", js: true do
  describe "policy link" do
    scenario "showing" do
      visit root_path
      expect(page).to have_link "cookies policy"
    end

    scenario "opens cookies policy page" do
      visit root_path
      click_link "cookies policy"
      expect(page).to have_content I18n.t('legal.cookies_policy.header')
    end
  end

  describe "privacy policy link" do
    scenario "not showing if it is empty" do
      Spree::Config[:privacy_policy_url] = nil
      visit root_path
      expect(page).to_not have_link "privacy policy"
    end

    scenario "showing configured privacy policy link" do
      Spree::Config[:privacy_policy_url] = "link_to_privacy_policy"
      visit root_path
      expect(page).to have_link "privacy policy", :href => "link_to_privacy_policy"
    end
  end
end
