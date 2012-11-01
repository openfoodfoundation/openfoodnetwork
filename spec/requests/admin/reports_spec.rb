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

  scenario "bulk co-op report" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Bulk Co-Op'

    page.should have_content 'Supplier'
  end

  scenario "payments reports" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Payment Reports'

    page.should have_content 'Payment State'
  end

  scenario "order cycle reports" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Order Cycle Reports'

    page.should have_content 'Supplier'
  end

end
