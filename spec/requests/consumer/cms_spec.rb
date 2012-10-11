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
    create(:cms_page, content: 'Home page content')

    # When I visit the home page
    visit spree.root_path

    # Then I should see my content
    page.should have_content 'Home page content'
  end

  scenario "viewing another products listing page does not display home page content" do
    # Given a CMS home page
    create(:cms_page, content: 'Home page content')

    # When I visit a products listing page
    visit spree.products_path

    # Then I should not see the home page content
    page.should_not have_content 'Home page content'
  end


  scenario "viewing the menu of CMS pages" do
    # Given some CMS pages
    home_page = create(:cms_page, content: 'Home')
    create(:cms_page, parent: home_page, label: 'One')
    create(:cms_page, parent: home_page, label: 'Two')
    create(:cms_page, parent: home_page, label: 'Three')

    # When I visit the home page
    visit spree.root_path

    # Then I should see a menu with these pages
    page.should have_selector 'ul#main-nav-bar li', :text => 'One'
    page.should have_selector 'ul#main-nav-bar li', :text => 'Two'
    page.should have_selector 'ul#main-nav-bar li', :text => 'Three'
  end

end
