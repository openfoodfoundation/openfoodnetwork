require 'spec_helper'

feature 'Multilingual', js: true do
  include WebHelper

  it 'has two locales available' do
    expect(Rails.application.config.i18n[:default_locale]).to eq 'en'
    expect(Rails.application.config.i18n[:locale]).to eq 'en'
    expect(Rails.application.config.i18n[:available_locales]).to eq ['en', 'es']
  end

  it 'can switch language by params' do
    visit root_path
    expect(get_i18n_locale).to eq 'en'
    expect(get_i18n_translation('label_shops')).to eq 'Shops'
    expect(page).to have_content 'Interested in getting on the Open Food Network?'
    expect(page).to have_content 'SHOPS'

    visit root_path(locale: 'es')
    expect(get_i18n_locale).to eq 'es'
    expect(get_i18n_translation('label_shops')).to eq 'Tiendas'
    expect(page).to have_content '¿Estás interesada en entrar en Open Food Network?'
    expect(page).to have_content 'TIENDAS'

    # I18n-js fallsback to 'en'
    visit root_path(locale: 'it')
    expect(get_i18n_locale).to eq 'it'
    expect(get_i18n_translation('label_shops')).to eq 'Shops'
    # This still is italian until we change enforce_available_locales to `true`
    expect(page).to have_content 'NEGOZI'
  end
end
