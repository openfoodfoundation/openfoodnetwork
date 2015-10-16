require 'spec_helper'

feature %q{
  As a site administrator
  I want to configure the site content
} do
  include AuthenticationWorkflow
  include WebHelper

  before do
    login_to_admin_section
    click_link 'Configuration'
    click_link 'Content'
  end

  scenario "filling in a setting shows the result on the home page" do
    fill_in 'footer_facebook_url', with: ''
    fill_in 'footer_twitter_url', with: 'http://twitter.com/me'
    fill_in 'footer_links_md', with: '[markdown link](/)'
    click_button 'Update'
    page.should have_content 'Your content has been successfully updated!'

    visit root_path

    # Then social media icons are only shown if they have a value
    page.should_not have_selector 'i.ofn-i_044-facebook'
    page.should     have_selector 'i.ofn-i_041-twitter'

    # And markdown is rendered
    page.should have_link 'markdown link'
  end

  scenario "uploading logos" do
    attach_file 'logo', "#{Rails.root}/app/assets/images/logo-white.png"
    click_button 'Update'
    page.should have_content 'Your content has been successfully updated!'

    ContentConfig.logo.to_s.should include "logo-white"
  end
end
