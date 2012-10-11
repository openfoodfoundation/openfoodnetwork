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
    click_link 'CMS Admin'
    page.should have_content "ComfortableMexicanSofa"

    click_link 'Spree Admin'
    page.should have_selector 'h1', :text => 'Administration'
  end

end
