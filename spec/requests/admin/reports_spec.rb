require "spec_helper"

feature %q{
    As an administrator
    I want numbers, all the numbers!
} do
  include AuthenticationWorkflow
  include WebHelper


  scenario "orders and distributors report" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Orders And Distributors'

    page.should have_content 'Order date'
  end

  scenario "group buys report" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Group Buys'

    page.should have_content 'Supplier'
  end

end
