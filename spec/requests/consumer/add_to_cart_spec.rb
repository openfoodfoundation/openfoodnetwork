require 'spec_helper'

feature %q{
    As a consumer
    I want to choose a distributor when adding products to my cart
    So that I can avoid making an order from many different distributors
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "adding the first product to the cart" do
    # Given a product and some distributors
    d1 = create(:distributor)
    d2 = create(:distributor)
    p = create(:product, :distributors => [d1])

    # When I choose a distributor
    visit spree.root_path
    click_link d2.name

    # When I add an item to my cart from a different distributor
    visit spree.product_path p
    select d1.name, :from => 'distributor_id'
    click_button 'Add To Cart'

    # Then the item should be in my cart
    order = Spree::Order.last
    order.line_items.first.product.should == p

    # And my order should have its distributor set to the chosen distributor
    order.distributor.should == d1
  end

  it "does not allow the user to change distributor after a product has been added to the cart" do
    # Given a product and some distributors
    d1 = create(:distributor)
    d2 = create(:distributor)
    p = create(:product, :distributors => [d1])

    # When I add a product to my cart (which sets my distributor)
    visit spree.product_path p
    click_button 'Add To Cart'
    page.should have_content "You are shopping at #{d1.name}"

    # Then I should not be able to change distributor
    visit spree.root_path
    page.should_not have_selector 'a', :text => d1.name
    page.should_not have_selector 'a', :text => d2.name
    page.should_not have_selector 'a', :text => 'Leave distributor'
  end

  context "adding a subsequent product to the cart" do
    it "does not allow the user to choose a distributor" do
      # Instead, they see "Your distributor for this order is XYZ"
      pending
    end

    it "does not allow the user to add a product from another distributor" do
      # No add to cart button
      # They see "Please complete your order at XYZ before shopping with another distributor."
      pending
    end
  end
end
