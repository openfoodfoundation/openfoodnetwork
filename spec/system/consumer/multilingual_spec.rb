# frozen_string_literal: true

require 'system_helper'

RSpec.describe 'Multilingual' do
  include AuthenticationHelper
  include WebHelper
  include CookieHelper

  let(:user) { create(:user) }

  it 'has three locales available' do
    expect(Rails.application.config.i18n[:default_locale]).to eq 'en_TST'
    expect(Rails.application.config.i18n[:locale]).to eq 'en_TST'
    expect(Rails.application.config.i18n[:available_locales]).to eq ['en_TST', 'es', 'pt', 'en']
  end

  it 'can switch language by params' do
    visit root_path
    expect(pick_i18n_locale).to eq 'en_TST'
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

  it "allows switching language via the main navigation" do
    visit root_path

    expect(page).to have_content 'SHOPS'

    find('.language-switcher').click
    within '.language-switcher .dropdown' do
      expect(page).not_to have_link 'English'
      expect(page).to have_link 'Español'

      click_link 'Español'
    end

    expect_menu_and_cookie_in_es
  end
end

def expect_menu_and_cookie_in_es
  expect(cookies_name['locale']).to have_attributes(value: "es")
  expect(page).to have_content 'TIENDAS'
end
