require 'spec_helper'

feature %q{
    As a consumer
    I want to see a list of distributors
    So that I can shop by a particular distributor
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "viewing a list of distributors" do
    # Given some distributors
    d1 = create(:distributor_enterprise)
    d2 = create(:distributor_enterprise)
    d3 = create(:distributor_enterprise)

    # And some of those distributors have a product
    create(:product, :distributors => [d1, d2])

    # When I go to the home page
    visit spree.root_path

    # Then I should see a list containing the distributors that have products
    page.should have_selector 'a', :text => d1.name
    page.should have_selector 'a', :text => d2.name
    page.should_not have_selector 'a', :text => d3.name
  end

  scenario "viewing a distributor" do
    # Given some distributors with products
    d1 = create(:distributor_enterprise, :long_description => "<p>Hello, world!</p>")
    d2 = create(:distributor_enterprise)
    p1 = create(:product, :distributors => [d1])
    p2 = create(:product, :distributors => [d2])

    # When I go to the first distributor page
    visit spree.root_path
    click_link d1.name

    # Then I should see the distributor details
    page.should have_selector 'h2', :text => d1.name
    page.should have_selector 'div.enterprise-description', :text => 'Hello, world!'

    # And I should see the first, but not the second product
    page.should have_content p1.name
    page.should_not have_content p2.name
  end

end
