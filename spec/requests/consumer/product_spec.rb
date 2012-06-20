require 'spec_helper'

feature %q{
    As a consumer
    I want to see products
    So that I can shop
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "viewing a product shows its supplier and distributor" do
    # Given a product with a supplier and distributor
    s = create(:supplier)
    d = create(:distributor)
    p = create(:product, :supplier => s, :distributors => [d])

    # When I view the product
    visit spree.product_path p

    # Then I should see the product's supplier and distributor
    page.should have_selector 'td', :text => s.name
    page.should have_selector 'td', :text => d.name
  end

end
