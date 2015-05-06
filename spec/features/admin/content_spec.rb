require 'spec_helper'

feature %q{
  As a site administrator
  I want to configure the site content
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "filling in a setting shows the result on the home page" do
    login_to_admin_section
    click_link 'Configuration'
    click_link 'Content'

    fill_in 'home_tagline_cta', with: 'Editable text'
    fill_in 'footer_facebook_url', with: ''
    fill_in 'footer_twitter_url', with: 'http://twitter.com/me'
    fill_in 'footer_links_md', with: '[markdown link](/)'
    click_button 'Update'
    page.should have_content 'Your content has been successfully updated!'

    visit root_path

    # The content should be shown
    page.should have_content 'Editable text'

    # And social media icons are only shown if they have a value
    page.should_not have_selector 'i.ofn-i_044-facebook'
    page.should     have_selector 'i.ofn-i_041-twitter'

    # And markdown is rendered
    page.should have_link 'markdown link'
  end
end
