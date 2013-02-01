require 'spec_helper'

feature %q{
    As a consumer
    I want to see a list of products from a supplier
    So that I can connect with them (and maybe buy stuff too)
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "viewing a list of suppliers in the sidebar" do
    # Given some suppliers
    s1 = create(:supplier_enterprise)
    s2 = create(:supplier_enterprise)
    s3 = create(:supplier_enterprise)

    # And some of those suppliers have a product
    create(:product, :supplier => s1)
    create(:product, :supplier => s3)

    # When I go to the home page
    visit spree.root_path

    # Then I should see a list containing all the suppliers that have products in stock
    page.should have_selector 'a', :text => s1.name
    page.should have_selector 'a', :text => s3.name
    page.should_not have_selector 'a', :text => s2.name
  end

  scenario "viewing a list of all suppliers" do
    # Given some suppliers
    s1 = create(:supplier_enterprise)
    s2 = create(:supplier_enterprise)
    s3 = create(:supplier_enterprise)

    # And some of those suppliers have a product
    create(:product, :supplier => s1)
    create(:product, :supplier => s3)

    # When I go to the suppliers listing page
    visit spree.root_path
    click_button 'Browse All Suppliers'

    # Then I should see a list containing all the suppliers
    page.should have_selector '#content a', :text => s1.name
    page.should have_selector '#content a', :text => s2.name
    page.should have_selector '#content a', :text => s3.name
  end

  scenario "viewing products provided by a supplier" do
    # Given a supplier with a product
    s1 = create(:supplier_enterprise, :name => 'Murrnong', :long_description => "<p>Hello, world!</p>")
    p1 = create(:product, :supplier => s1)

    # And a different supplier with another product
    s2 = create(:supplier_enterprise, :name => 'Red Herring')
    p2 = create(:product, :supplier => s2)

    # When I select the first supplier
    visit spree.root_path
    click_link s1.name

    # Then I should see the supplier details
    page.should have_selector 'h2', :text => s1.name
    page.should have_selector 'div.enterprise-description', :text => 'Hello, world!'

    # And I should see the first, but not the second product
    page.should have_content p1.name
    page.should_not have_content p2.name
  end
end
