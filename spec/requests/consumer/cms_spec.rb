require 'spec_helper'

feature %q{
    In order to learn about food
    As a user of the site
    I want to see static content pages
} do
  include AuthenticationWorkflow
  include WebHelper


  scenario "viewing the home page" do
    # Given a CMS home page
    cms_page = create(:cms_page, content: 'Home page content')

    # When I visit the home page
    visit spree.root_path

    # Then I should see my content
    page.should have_content 'Home page content'
  end

end
