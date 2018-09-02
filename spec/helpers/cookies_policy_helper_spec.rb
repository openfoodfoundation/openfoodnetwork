require 'spec_helper'

describe CookiesPolicyHelper, type: :helper do
  
  # keeps global state unchanged
  around do |example|
    original_locale  = I18n.locale
    original_matomo_url = Spree::Config.matomo_url
    example.run
    Spree::Config.matomo_url = original_matomo_url
    I18n.locale = original_locale
  end

  describe "matomo optout iframe src" do
    scenario "includes matomo URL" do  
      Spree::Config.matomo_url = "http://matomo.org/"
      expect(helper.matomo_iframe_src).to include Spree::Config.matomo_url
    end

    scenario "is not nil, when matomo url is nil" do
      Spree::Config.matomo_url = nil
      expect(helper.matomo_iframe_src).to_not eq nil
    end
  end

  describe "language from locale" do
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
