# frozen_string_literal: true

require 'system_helper'

describe "Footer Links" do
  describe "policy link" do
    it "showing" do
      visit root_path
      expect(page).to have_link "cookies policy"
    end

    shared_examples "opens the cookie policy modal" do |content|
      it "with the right content" do
        within "div.reveal-modal" do
          expect(page).to have_content content
        end
      end
    end

    context "when english is the default language" do
      before do
        visit root_path
        click_link "cookies policy"
      end

      it_behaves_like "opens the cookie policy modal", "How We Use Cookies"
    end

    context "when spanish is selected" do
      before do
        visit root_path
        find('.language-switcher').click
        within '.language-switcher .dropdown' do
          find('li a[href="/locales/es"]').click
        end
        click_link "política de cookies"
      end

      it_behaves_like "opens the cookie policy modal", "Cómo utilizamos las cookies"
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
