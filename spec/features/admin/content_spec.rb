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
    click_button 'Update'
    page.should have_content 'Your content has been successfully updated!'

    visit root_path
    page.should have_content 'Editable text'
  end
end
