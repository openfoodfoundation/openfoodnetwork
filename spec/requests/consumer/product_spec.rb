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

  describe "viewing distributor details" do
    context "without Javascript" do
      it "displays a holding message when no distributor is selected" do
        p = create(:product)

        visit spree.product_path p

        page.should have_selector '#product-distributor-details', :text => 'When you select a distributor for your order, their address and pickup times will be displayed here.'
      end

      it "displays distributor details when one is selected"
    end

    context "with Javascript" do
      it "changes distributor details when the distributor is changed"
    end
  end


end
