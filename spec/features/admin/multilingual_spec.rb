require 'spec_helper'

feature 'Multilingual', js: true do
  include AuthenticationWorkflow
  include WebHelper

  background do
    login_to_admin_section
  end

  it 'has two locales available' do
    expect(Rails.application.config.i18n[:default_locale]).to eq 'en'
    expect(Rails.application.config.i18n[:locale]).to eq 'en'
    expect(Rails.application.config.i18n[:available_locales]).to eq ['en', 'es']
  end

  it 'can switch language by params' do
    expect(get_i18n_locale).to eq 'en'
    expect(get_i18n_translation('spree_admin_overview_enterprises_header')).to eq 'My Enterprises'
    expect(page).to have_content 'My Enterprises'

    visit spree.admin_path(locale: 'es')
    expect(get_i18n_locale).to eq 'es'
    expect(get_i18n_translation('spree_admin_overview_enterprises_header')).to eq 'Mis Organizaciones'
    expect(page).to have_content 'Mis Organizaciones'
  end

  it 'fallbacks to default_locale' do
    pending 'current spree core has a bug if not available locale is provided'
    # undefined method `delete_if' for "translation missing: it.date.month_names":String
    # inside core/app/views/spree/admin/shared/_translations.html.erb

    # I18n-js fallsback to 'en'
    visit spree.admin_path(locale: 'it')
    expect(get_i18n_locale).to eq 'it'
    expect(get_i18n_translation('spree_admin_overview_enterprises_header')).to eq 'My Enterprises'
    # This still is italian until we change enforce_available_locales to `true`
    expect(page).to have_content 'Le Mie Aziende'
  end
end
