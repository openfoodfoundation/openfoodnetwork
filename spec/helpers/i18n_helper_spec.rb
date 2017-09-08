require 'spec_helper'

describe I18nHelper do
  let(:user) { create(:user) }

  context "as guest" do
    before do
      allow(helper).to receive(:spree_current_user) { nil }
    end

    it "sets the default locale" do
      helper.set_locale
      expect(I18n.locale).to eq :en
    end

    it "sets the chosen locale" do
      allow(helper).to receive(:params) { {locale: "es"} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "remembers the chosen locale" do
      allow(helper).to receive(:params) { {locale: "es"} }
      helper.set_locale

      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "ignores unavailable locales" do
      allow(helper).to receive(:params) { {locale: "xx"} }
      helper.set_locale
      expect(I18n.locale).to eq :en
    end

    it "remembers the last chosen locale" do
      allow(helper).to receive(:params) { {locale: "en"} }
      helper.set_locale

      allow(helper).to receive(:params) { {locale: "es"} }
      helper.set_locale

      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "remembers the chosen locale after logging in" do
      allow(helper).to receive(:params) { {locale: "es"} }
      helper.set_locale

      # log in
      allow(helper).to receive(:spree_current_user) { user }
      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "forgets the chosen locale without cookies" do
      allow(helper).to receive(:params) { {locale: "es"} }
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
      allow(helper).to receive(:params) { {locale: "es"} }
      helper.set_locale
      expect(I18n.locale).to eq :es
      expect(user.locale).to eq "es"
    end

    it "remembers the chosen locale" do
      allow(helper).to receive(:params) { {locale: "es"} }
      helper.set_locale

      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "remembers the last chosen locale" do
      allow(helper).to receive(:params) { {locale: "en"} }
      helper.set_locale

      allow(helper).to receive(:params) { {locale: "es"} }
      helper.set_locale

      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "remembers the chosen locale after logging out" do
      allow(helper).to receive(:params) { {locale: "es"} }
      helper.set_locale

      # log out
      allow(helper).to receive(:spree_current_user) { nil }
      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end

    it "remembers the chosen locale on another computer" do
      allow(helper).to receive(:params) { {locale: "es"} }
      helper.set_locale
      expect(cookies[:locale]).to eq "es"

      # switch computer / browser or loose cookies
      cookies.delete :locale

      allow(helper).to receive(:params) { {} }
      helper.set_locale
      expect(I18n.locale).to eq :es
    end
  end
end
