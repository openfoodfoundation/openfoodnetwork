require 'spec_helper'

feature %q{
    In order to provide content to users of the site
    As an administrator
    I want to access the CMS admin site
} do
  include AuthenticationWorkflow
  include WebHelper


  scenario "admin can access CMS admin and return to Spree admin" do
    login_to_admin_section
    click_link 'Configuration'
    click_link 'CMS Admin'
    page.should have_content "ComfortableMexicanSofa"

    click_link 'Spree Admin'
    current_path.should == spree.admin_path
  end

  scenario "anonymous user can't access CMS admin" do
    visit cms_admin_path
    page.should_not have_content "ComfortableMexicanSofa"
    page.should have_content "Login"
  end

  scenario "non-admin user can't access CMS admin" do
    login_to_consumer_section
    visit cms_admin_path
    page.should_not have_content "ComfortableMexicanSofa"
    page.should have_content "Home"
  end

end
