# frozen_string_literal: true

require 'system_helper'

describe 'Multilingual' do
  include AuthenticationHelper
  include WebHelper
  let(:admin_role) { Spree::Role.find_or_create_by!(name: 'admin') }
  let(:admin_user) { create(:user) }

  before do
    admin_user.spree_roles << admin_role
    login_as admin_user
    visit spree.admin_dashboard_path
  end

  it 'has three locales available' do
    expect(Rails.application.config.i18n[:default_locale]).to eq 'en'
    expect(Rails.application.config.i18n[:locale]).to eq 'en'
    expect(Rails.application.config.i18n[:available_locales]).to eq ['en', 'es', 'pt']
  end

  it 'can switch language by params' do
    expect(get_i18n_locale).to eq 'en'
    expect(get_i18n_translation('spree_admin_overview_enterprises_header')).to eq 'My Enterprises'
    expect(page).to have_content 'My Enterprises'
    expect(admin_user.locale).to be_nil

    visit spree.admin_dashboard_path(locale: 'es')
    expect(get_i18n_locale).to eq 'es'
    expect(get_i18n_translation('spree_admin_overview_enterprises_header'))
      .to eq 'Mis Organizaciones'
    expect(page).to have_content 'Mis Organizaciones'
    admin_user.reload
    expect(admin_user.locale).to eq 'es'
  end

  it 'fallbacks to default_locale' do
    visit spree.admin_dashboard_path(locale: 'it')
    expect(get_i18n_locale).to eq 'en'
    expect(get_i18n_translation('spree_admin_overview_enterprises_header')).to eq 'My Enterprises'
    expect(page).to have_content 'My Enterprises'
    expect(admin_user.locale).to be_nil
  end
end
