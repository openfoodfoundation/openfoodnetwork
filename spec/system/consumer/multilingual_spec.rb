# frozen_string_literal: true

require 'system_helper'

RSpec.describe 'Multilingual' do
  include AuthenticationHelper
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper
  include CookieHelper

  it 'has three locales available' do
    expect(Rails.application.config.i18n[:default_locale]).to eq 'en'
    expect(Rails.application.config.i18n[:locale]).to eq 'en'
    expect(Rails.application.config.i18n[:available_locales]).to eq ['en', 'es', 'pt']
  end

  context 'can switch language by params' do
    it 'in root path' do
      visit root_path
      expect(pick_i18n_locale).to eq 'en'
      expect(get_i18n_translation('label_shops')).to eq 'Shops'
      expect(cookies_name).not_to include('locale')
      expect(page).to have_content 'SHOPS'

      visit root_path(locale: 'es')
      expect(pick_i18n_locale).to eq 'es'
      expect(get_i18n_translation('label_shops')).to eq 'Tiendas'
      expect_menu_and_cookie_in_es

      # it is not in the list of available of available_locales
      visit root_path(locale: 'it')
      expect(pick_i18n_locale).to eq 'es'
      expect(get_i18n_translation('label_shops')).to eq 'Tiendas'
      expect_menu_and_cookie_in_es
    end
  end

  context 'with user' do
    let(:user) { create(:user) }

    it 'updates user locale from cookie if it is empty' do
      visit root_path(locale: 'es')

      expect_menu_and_cookie_in_es
      expect(user.locale).to be_nil
      login_as user
      visit root_path

      expect_menu_and_cookie_in_es

      # The user's locale is not changed if the language was chosen before
      # login. Is it a bug or a feature? Probably not important...
      expect(user.reload.locale).to eq nil

      visit root_path(locale: 'es')
      expect(user.reload.locale).to eq 'es'

      logout

      expect_menu_and_cookie_in_es
      expect(page).to have_content '¿Estás interesada en entrar en Open Food Network?'
    end
  end

  describe "using the language switcher UI" do
    context "when there are multiple languages available" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("LOCALE").and_return("en")
        allow(ENV).to receive(:[]).with("AVAILABLE_LOCALES").and_return("en,es")
      end

      it "allows switching language via the main navigation" do
        visit root_path

        expect(page).to have_content 'SHOPS'

        find('.language-switcher').click
        within '.language-switcher .dropdown' do
          expect(page).not_to have_link 'English', href: '/locales/en'
          expect(page).to have_link 'Español', href: '/locales/es'

          find('li a[href="/locales/es"]').click
        end

        expect_menu_and_cookie_in_es
      end
    end
  end
end

def expect_menu_and_cookie_in_es
  expect(cookies_name['locale']).to have_attributes(value: "es")
  expect(page).to have_content 'TIENDAS'
end
