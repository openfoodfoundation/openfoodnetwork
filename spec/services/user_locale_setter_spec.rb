# frozen_string_literal: true

require 'spec_helper'

describe UserLocaleSetter do
  let(:user) { create(:user) }
  let(:default_locale) { I18n.default_locale }
  let(:locale_params) { {} }
  let(:cookies) { {} }
  let(:service) { UserLocaleSetter.new(user, locale_params, cookies) }

  describe "#set_locale" do
    describe "persists selected locale from params" do
      let(:locale_params) { "es" }

      context "when the user is logged in" do
        it "saves selected locale to user.locale and cookies[:locale]" do
          service.set_locale

          expect(user.reload.locale).to eq "es"
          expect(cookies).to eq({ locale: "es" })
        end
      end

      context "when the user is not logged in" do
        it "saves selected locale to cookies[:locale]" do
          service.set_locale

          expect(cookies).to eq({ locale: "es" })
        end
      end
    end

    describe "sets the current locale" do
      context "when the user is logged in" do
        context "and has a valid locale saved" do
          before { user.update(locale: "es") }

          it "applies the user's locale" do
            service.set_locale

            expect(I18n.locale).to eq :es
          end
        end

        context "and has an invalid locale saved" do
          before { user.update(locale: "xx") }

          it "applies the default locale" do
            service.set_locale

            expect(I18n.locale).to eq I18n.default_locale
          end
        end

        context "and has no locale saved" do
          before { user.update(locale: nil) }

          it "applies the locale from cookies if present" do
            cookies[:locale] = "es"
            service.set_locale

            expect(I18n.locale).to eq :es
          end

          it "applies the default locale otherwise " do
            service.set_locale

            expect(I18n.locale).to eq I18n.default_locale
          end
        end
      end

      context "when the user is not logged in" do
        let(:user) { nil }

        context "with a locale set in cookies" do
          it "applies the value from cookies" do
            cookies[:locale] = "es"
            service.set_locale

            expect(I18n.locale).to eq :es
          end
        end

        context "with no locale set in cookies" do
          it "applies the default locale" do
            service.set_locale

            expect(I18n.locale).to eq I18n.default_locale
          end
        end
      end
    end
  end

  describe "#ensure_valid_locale_persisted" do
    context "when a user is present" do
      context "and has an unavailable locale saved" do
        before { user.update(locale: "xx") }

        context "with no locale set in cookies" do
          it "set the user's locale to the default" do
            service.ensure_valid_locale_persisted

            expect(user.reload.locale).to eq default_locale.to_s
          end
        end

        context "with a locale set in cookies" do
          let(:cookies) { { locale: "es" } }

          it "set the user's locale to the cookie value" do
            service.ensure_valid_locale_persisted

            expect(user.reload.locale).to eq "es"
          end
        end
      end
    end
  end

  describe "#valid_current_locale" do
    let(:service) { UserLocaleSetter.new(user) }

    context "when the user has a locale set" do
      it "returns the user's locale" do
        user.update(locale: "es")
        expect(service.valid_current_locale).to eq "es"
      end
    end

    context "when the user has no locale set" do
      it "returns the default locale" do
        expect(service.valid_current_locale).to eq default_locale
      end
    end

    context "when the given user argument is nil" do
      let(:user) { nil }

      it "returns the default locale" do
        expect(service.valid_current_locale).to eq default_locale
      end
    end
  end
end
