# frozen_string_literal: true

require 'spec_helper'

describe I18nHelper, type: :helper do
  let(:user) { create(:user) }
  let(:cookies) { {} }

  before do
    allow(helper).to receive(:cookies) { cookies }
  end

  # In the real world, the helper is called in every request and sets
  # I18n.locale to the chosen locale or the default. For testing purposes we
  # have to restore I18n.locale for unit tests that don't call the helper, but
  # rely on translated strings.
  around do |example|
    locale = I18n.locale
    example.run
    I18n.locale = locale
  end

  context "as guest" do
    before do
      allow(helper).to receive(:spree_current_user) { nil }
    end

    it "sets the default locale" do
      helper.set_locale
      expect(I18n.locale).to eq :en
    end

    it "sets the chosen locale" do
      allow(helper).to receive(:params) { { locale: "es" } }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "remembers the chosen locale" do
      allow(helper).to receive(:params) { { locale: "es" } }
      helper.set_locale

      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "ignores unavailable locales" do
      allow(helper).to receive(:params) { { locale: "xx" } }
      helper.set_locale
      expect(I18n.locale).to eq :en
    end

    it "remembers the last chosen locale" do
      allow(helper).to receive(:params) { { locale: "en" } }
      helper.set_locale

      allow(helper).to receive(:params) { { locale: "es" } }
      helper.set_locale

      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "remembers the chosen locale after logging in" do
      allow(helper).to receive(:params) { { locale: "es" } }
      helper.set_locale

      # log in
      allow(helper).to receive(:spree_current_user) { user }
      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "forgets the chosen locale without cookies" do
      allow(helper).to receive(:params) { { locale: "es" } }
      helper.set_locale

      # clean up cookies
      cookies.delete :locale

      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :en
    end
  end

  context "logged in" do
    before do
      allow(helper).to receive(:spree_current_user) { user }
    end

    it "sets the default locale" do
      helper.set_locale
      expect(I18n.locale).to eq :en
    end

    it "sets the chosen locale" do
      allow(helper).to receive(:params) { { locale: "es" } }
      helper.set_locale
      expect(I18n.locale).to eq :es
      expect(user.locale).to eq "es"
    end

    it "remembers the chosen locale" do
      allow(helper).to receive(:params) { { locale: "es" } }
      helper.set_locale

      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "remembers the last chosen locale" do
      allow(helper).to receive(:params) { { locale: "en" } }
      helper.set_locale

      allow(helper).to receive(:params) { { locale: "es" } }
      helper.set_locale

      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "remembers the chosen locale after logging out" do
      allow(helper).to receive(:params) { { locale: "es" } }
      helper.set_locale

      # log out
      allow(helper).to receive(:spree_current_user) { nil }
      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "remembers the chosen locale on another computer" do
      allow(helper).to receive(:params) { { locale: "es" } }
      helper.set_locale
      expect(cookies.fetch(:locale)).to eq "es"

      # switch computer / browser or loose cookies
      cookies.delete :locale

      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end
  end

  context "#valid_locale" do
    around do |example|
      original_default_locale = I18n.default_locale
      original_available_locales = Rails.application.config.i18n.available_locales
      I18n.default_locale = "es"
      Rails.application.config.i18n.available_locales = ["es", "pt"]
      example.run
      I18n.default_locale = original_default_locale
      Rails.application.config.i18n.available_locales = original_available_locales
    end

    let(:user) { build(:user) }

    it "returns default locale if given user is nil" do
      expect(helper.valid_locale(nil)).to eq I18n.default_locale
    end

    it "returns default locale if locale of given user is nil" do
      expect(helper.valid_locale(user)).to eq I18n.default_locale
    end

    it "returns default locale if locale of given user is not available" do
      user.locale = "cn"
      expect(helper.valid_locale(user)).to eq I18n.default_locale
    end

    it "returns the locale of the given user if available" do
      user.locale = "pt"
      expect(helper.valid_locale(user)).to eq "pt"
    end
  end
end
