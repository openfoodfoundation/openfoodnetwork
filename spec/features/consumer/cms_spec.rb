require 'spec_helper'

feature %q{
    In order to learn about food
    As a user of the site
    I want to see static content pages
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    create(:distributor_enterprise, :name => 'Edible garden')
  end

  scenario "viewing shop front does not display home page content" do
    # Given a CMS home page
    create(:cms_page, content: 'Home page content')

    # When I visit the home page
    visit spree.root_path

    # and proceed to the shop front
    click_on 'Edible garden'

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

    # and proceed to the shop front
    click_on "Edible garden"

    # Then I should see a menu with these pages
    page.should have_selector 'ul#main-nav-bar li', :text => 'One'
    page.should have_selector 'ul#main-nav-bar li', :text => 'Two'
    page.should have_selector 'ul#main-nav-bar li', :text => 'Three'
  end

  scenario "viewing a page from the CMS menu" do
    # Given some CMS pages
    home_page = create(:cms_page, content: 'Home')
    create(:cms_page, parent: home_page, label: 'One')
    create(:cms_page, parent: home_page, label: 'Two', content: 'This is the page')
    create(:cms_page, parent: home_page, label: 'Three')

    # When I go to one of the pages
    visit spree.root_path
    click_on "Edible garden"
    click_link 'Two'

    # Then I should see the page
    page.should have_content 'This is the page'
  end

end
