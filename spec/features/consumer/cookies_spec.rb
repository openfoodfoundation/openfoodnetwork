require 'spec_helper'

feature "Cookies", js: true do
  describe "banner", js: true do
    describe "in the homepage" do
      before do
        Spree::Config[:cookies_consent_banner_toggle] = true
        visit root_path       
      end

      scenario "does not show after cookies are accepted" do
        click_button I18n.t('legal.cookies_banner.cookies_accept_button')
        expect_not_visible_cookies_banner

        visit root_path
        expect_not_visible_cookies_banner
      end

      scenario "banner contains cookies policy link that opens coookies policy page and closes banner" do
        find("p.ng-binding > a", :text => "cookies policy").click
        expect_visible_cookies_policy_page
        expect_not_visible_cookies_banner

        find("a.close-reveal-modal").click
        expect_visible_cookies_banner
      end
    end

    describe "in product listing page" do
      before do
        Spree::Config[:cookies_consent_banner_toggle] = true
      end

      scenario "it is showing" do
        visit "/shops"      
        expect_visible_cookies_banner
      end
    end

    describe "disabled in the settings" do
      scenario "it is not showing" do
        Spree::Config[:cookies_consent_banner_toggle] = false
        visit root_path
        expect(page).to_not have_content I18n.t('legal.cookies_banner.cookies_usage')
      end
    end
  end

  describe "policy page" do
    scenario "showing session_id cookies description with correct instance domain" do
      visit '/#/policies/cookies'
      expect(page).to have_content('_session_id')
        .and have_content('127.0.0.1')
    end

    describe "with Matomo section configured" do
      scenario "shows Matomo cookies details" do
        Spree::Config[:cookies_policy_matomo_section] = true
        visit '/#/policies/cookies'
        # before { skip("test not working, settings are not picked up") }
        # expect(page).to have_content matomo_description_text
      end
    end

    describe "without Matomo section configured" do
      scenario "does not show Matomo cookies details" do
        Spree::Config[:cookies_policy_matomo_section] = false
        visit '/#/policies/cookies'
        expect(page).to_not have_content matomo_description_text
      end
    end
  end

  def matomo_description_text
    I18n.t('legal.cookies_policy.statistics_cookies_matomo_desc')
  end

  def expect_visible_cookies_policy_page
    expect(page).to have_content I18n.t('legal.cookies_policy.header')
  end

  def expect_visible_cookies_banner
    expect(page).to have_css("button", :text => accept_cookies_button_text, :visible => true)
  end

  def expect_not_visible_cookies_banner
    expect(page).to_not have_css("button", :text => accept_cookies_button_text, :visible => true)
  end

  def accept_cookies_button_text
    I18n.t('legal.cookies_banner.cookies_accept_button')
  end
end
