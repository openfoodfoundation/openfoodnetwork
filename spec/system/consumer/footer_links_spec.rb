# frozen_string_literal: true

require 'system_helper'

describe "Footer Links" do
  describe "policy link" do
    it "showing" do
      visit root_path
      expect(page).to have_link "cookies policy"
    end

    it "opens cookies policy page" do
      visit root_path
      click_link "cookies policy"
      within "div.reveal-modal" do
        expect(page).to have_content "How We Use Cookies"
      end
    end
  end

  describe "privacy policy link" do
    it "not showing if it is empty" do
      Spree::Config[:privacy_policy_url] = nil
      visit root_path
      expect(page).to have_no_link "privacy policy"
    end

    it "showing configured privacy policy link" do
      Spree::Config[:privacy_policy_url] = "link_to_privacy_policy"
      visit root_path
      expect(page).to have_link "privacy policy", href: "link_to_privacy_policy"
    end
  end
end
