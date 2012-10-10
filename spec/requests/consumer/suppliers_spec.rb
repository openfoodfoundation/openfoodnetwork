require 'spec_helper'

feature %q{
    As a consumer
    I want to see a list of products from a supplier
    So that I can connect with them (and maybe buy stuff too)
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "viewing a list of suppliers" do
    # Given some suppliers
    s1 = create(:supplier)
    s2 = create(:supplier)
    s3 = create(:supplier)

    # When I go to the home page
    visit spree.root_path

    # Then I should see a list containing all the suppliers
    [s1, s2, s3].each { |s| page.should have_selector 'a', :text => s.name }
  end

  scenario "viewing products provided by a supplier" do
    # Given a supplier with a product
    s = create(:supplier, :name => 'Murrnong')
    p = create(:product, :supplier => s)

    # When I select the supplier
    visit spree.root_path
    click_link s.name

    # Then I should see the supplier details
    page.should have_selector 'h2', :text => s.name
    page.should have_selector 'div.supplier-description', :text => s.long_description

    # And I should see the product
    page.should have_content p.name
  end
end
