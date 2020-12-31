# frozen_string_literal: true

require 'spec_helper'

module Web
  describe CookiesPolicyHelper, type: :helper do
    # keeps global state unchanged
    around do |example|
      original_locale = I18n.locale
      original_matomo_url = Spree::Config.matomo_url
      example.run
      Spree::Config.matomo_url = original_matomo_url
      I18n.locale = original_locale
    end

    describe "matomo optout iframe src" do
      describe "when matomo url is set" do
        before do
          Spree::Config.matomo_url = "http://matomo.org/"
        end

        scenario "includes the matomo URL" do
          expect(helper.matomo_iframe_src).to include Spree::Config.matomo_url
        end

        scenario "is not equal to the matomo URL" do
          expect(helper.matomo_iframe_src).to_not eq Spree::Config.matomo_url
        end
      end

      scenario "is not nil, when matomo url is nil" do
        Spree::Config.matomo_url = nil
        expect(helper.matomo_iframe_src).to_not eq nil
      end
    end

    describe "language from locale" do
      # keeps global state unchanged
      around do |example|
        original_available_locales = I18n.available_locales
        I18n.available_locales = ['en', 'en_GB', '']
        example.run
        I18n.available_locales = original_available_locales
      end

      scenario "when locale is the language" do
        I18n.locale = "en"
        expect(helper.locale_language).to eq "en"
      end

      scenario "is empty when locale is empty" do
        I18n.locale = ""
        expect(helper.locale_language).to be_empty
      end

      scenario "is only the language, when locale includes country" do
        I18n.locale = "en_GB"
        expect(helper.locale_language).to eq "en"
      end
    end
  end
end
