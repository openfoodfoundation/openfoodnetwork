require 'spec_helper'

feature '
  As a site administrator
  I want to configure the site content
' do
  include AuthenticationHelper
  include WebHelper

  before do
    login_as_admin_and_visit spree.edit_admin_general_settings_path
    click_link 'Content'
  end

  scenario "filling in a setting shows the result on the home page" do
    fill_in 'footer_facebook_url', with: ''
    fill_in 'footer_twitter_url', with: 'http://twitter.com/me'
    fill_in 'footer_links_md', with: '[markdown link](/)'
    click_button 'Update'
    expect(page).to have_content 'Your content has been successfully updated!'

    visit root_path

    # Then social media icons are only shown if they have a value
    expect(page).not_to have_selector 'i.ofn-i_044-facebook'
    expect(page).to     have_selector 'i.ofn-i_041-twitter'

    # And markdown is rendered
    expect(page).to have_link 'markdown link'
  end

  scenario "uploading logos" do
    attach_file 'logo', "#{Rails.root}/app/assets/images/logo-white.png"
    click_button 'Update'
    expect(page).to have_content 'Your content has been successfully updated!'

    expect(ContentConfig.logo.to_s).to include "logo-white"
  end

  scenario "setting user guide link" do
    fill_in 'user_guide_link', with: 'http://www.openfoodnetwork.org/platform/user-guide/'
    click_button 'Update'

    expect(page).to have_content 'Your content has been successfully updated!'

    visit spree.admin_dashboard_path

    expect(page).to have_link('User Guide', href: 'http://www.openfoodnetwork.org/platform/user-guide/')
    expect(find_link('User Guide')[:target]).to eq('_blank')
  end
end
