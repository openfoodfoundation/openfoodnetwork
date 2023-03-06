# frozen_string_literal: true

require 'system_helper'

describe "Cookies" do
  describe "banner" do
    # keeps banner toggle config unchanged
    around do |example|
      original_banner_toggle = Spree::Config[:cookies_consent_banner_toggle]
      example.run
      Spree::Config[:cookies_consent_banner_toggle] = original_banner_toggle
    end

    context "in the homepage" do
      before do
        Spree::Config[:cookies_consent_banner_toggle] = true
        visit_root_path_and_wait
      end

      scenario "does not show after cookies are accepted" do
        accept_cookies_and_wait
        expect_not_visible_cookies_banner

        visit_root_path_and_wait
        expect_not_visible_cookies_banner
      end

      scenario "banner contains cookies policy link that opens coookies policy page and closes banner" do
        click_banner_cookies_policy_link_and_wait
        expect_visible_cookies_policy_page
        expect_not_visible_cookies_banner

        close_cookies_policy_page_and_wait
        expect_visible_cookies_banner
      end

      scenario "does not show after cookies are accepted, and policy page is opened through the footer, and closed again (bug #2599)" do
        accept_cookies_and_wait
        expect_not_visible_cookies_banner

        click_footer_cookies_policy_link_and_wait
        expect_visible_cookies_policy_page
        expect_not_visible_cookies_banner

        close_cookies_policy_page_and_wait
        expect_not_visible_cookies_banner
      end
    end

    context "in product listing page" do
      before do
        Spree::Config[:cookies_consent_banner_toggle] = true
      end

      scenario "it is showing" do
        visit "/shops"
        expect_visible_cookies_banner
      end
    end

    context "disabled in the settings" do
      scenario "it is not showing" do
        Spree::Config[:cookies_consent_banner_toggle] = false
        visit root_path
        expect(page).to have_no_content 'This site uses cookies in order to make your navigation frictionless and secure, and to help us understand how you use it in order to improve the features we offer.'
      end
    end
  end

  describe "policy page" do
    # keeps config unchanged
    around do |example|
      original_matomo_config = Spree::Config[:cookies_policy_matomo_section]
      original_matomo_url_config = Spree::Config[:matomo_url]
      example.run
      Spree::Config[:cookies_policy_matomo_section] = original_matomo_config
      Spree::Config[:matomo_url] = original_matomo_url_config
    end

    scenario "shows session_id cookies description with correct instance domain" do
      visit '/#/policies/cookies'
      expect(page).to have_content('_ofn_session_id')
        .and have_content('127.0.0.1')
    end

    context "without Matomo section configured" do
      scenario "does not show Matomo cookies details and does not show Matomo optout text" do
        Spree::Config[:cookies_policy_matomo_section] = false
        visit_cookies_policy_page
        expect(page).to have_no_content matomo_description_text
        expect(page).to have_no_content matomo_opt_out_iframe
      end
    end

    context "with Matomo section configured" do
      before do
        Spree::Config[:cookies_policy_matomo_section] = true
      end

      scenario "shows Matomo cookies details" do
        visit_cookies_policy_page
        expect(page).to have_content matomo_description_text
      end

      context "with Matomo integration enabled" do
        scenario "shows Matomo optout iframe" do
          Spree::Config[:matomo_url] = "https://0000.innocraft.cloud/"
          visit_cookies_policy_page
          expect(page).to have_content matomo_opt_out_iframe
          expect(page).to have_selector("iframe")
        end
      end

      context "with Matomo integration disabled" do
        scenario "does not show Matomo iframe" do
          Spree::Config[:cookies_policy_matomo_section] = true
          Spree::Config[:matomo_url] = ""
          visit_cookies_policy_page
          expect(page).to have_no_content matomo_opt_out_iframe
          expect(page).to have_no_selector("iframe")
        end
      end
    end
  end

  def expect_visible_cookies_policy_page
    expect(page).to have_content 'How We Use Cookies'
  end

  def expect_visible_cookies_banner
    expect(page).to have_css("button", text: accept_cookies_button_text)
  end

  def expect_not_visible_cookies_banner
    expect(page).to have_no_css("button", text: accept_cookies_button_text)
  end

  def accept_cookies_button_text
    'Accept Cookies'
  end

  def visit_root_path_and_wait
    visit root_path
    sleep 1
  end

  def accept_cookies_and_wait
    click_button accept_cookies_button_text
    sleep 2
  end

  def click_banner_cookies_policy_link_and_wait
    find("p.ng-binding > a", text: "cookies policy").click
    sleep 2
  end

  def click_footer_cookies_policy_link_and_wait
    find(".legal a", text: "cookies policy").click
    sleep 2
  end

  def close_cookies_policy_page_and_wait
    find("a.close-reveal-modal").click
    sleep 2
  end

  def visit_cookies_policy_page
    visit '/#/policies/cookies'
  end

  def matomo_description_text
    'Matomo first party cookies to collect statistics.'
  end

  def matomo_opt_out_iframe
    'Do you want to opt-out of Matomo analytics? We don’t collect any personal data, and Matomo helps us to improve our service, but we respect your choice :-)'
  end
end
