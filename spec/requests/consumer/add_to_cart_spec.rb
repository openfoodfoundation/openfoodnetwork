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
    create(:product, :distributors => [d2])

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
    page.should_not have_selector "a[href*='select']", :text => d1.name
    page.should_not have_selector "a[href*='select']", :text => d2.name
    page.should_not have_selector "a", :text => 'Leave distributor'
  end

  context "adding a subsequent product to the cart" do
    it "does not allow the user to choose a distributor" do
      # Given a product under a distributor
      d = create(:distributor)
      p = create(:product, :distributors => [d])

      # And a product in my cart
      visit spree.product_path p
      click_button 'Add To Cart'

      # When I go to add it again, I should not have a choice of distributor
      visit spree.product_path p
      page.should_not have_selector 'select#distributor_id'
      page.should     have_selector '.distributor-fixed', :text => "Your distributor for this order is #{d.name}"
    end

    it "does not allow the user to add a product from another distributor" do
      # Given two products, each at a different distributor
      d1 = create(:distributor)
      d2 = create(:distributor)
      p1 = create(:product, :distributors => [d1])
      p2 = create(:product, :distributors => [d2])

      # When I add one of them to my cart
      visit spree.product_path p1
      click_button 'Add To Cart'

      # And I attempt to add the other
      visit spree.product_path p2

      # Then I should not be allowed to add the product
      page.should_not have_selector "button#add-to-cart-button"
      page.should have_content "Please complete your order at #{d1.name} before shopping with another distributor."
    end

    it "adds products with valid distributors" do
      # Given two products, each at the same distributor
      d = create(:distributor)
      p1 = create(:product, :distributors => [d])
      p2 = create(:product, :distributors => [d])

      # When I add the first to my cart
      visit spree.product_path p1
      click_button 'Add To Cart'

      # And I add the second
      visit spree.product_path p2
      click_button 'Add To Cart'

      # Then both should be in my cart
      visit spree.cart_path
      page.should have_selector 'h4 a', :text => p1.name
      page.should have_selector 'h4 a', :text => p2.name
    end
  end

  scenario "adding a product to the cart for a group buy" do
    # Given a group buy product and a distributor
    d = create(:distributor)
    p = create(:product, :distributors => [d], :group_buy => true)

    # When I add the item to my cart
    visit spree.product_path p
    fill_in "variants_#{p.master.id}", :with => 2
    fill_in "variant_attributes_#{p.master.id}_max_quantity", :with => 3
    click_button 'Add To Cart'

    # Then the item should be in my cart with correct quantities
    order = Spree::Order.last
    li = order.line_items.first
    li.product.should == p
    li.quantity.should == 2
    li.max_quantity.should == 3
  end

  scenario "adding a product with variants to the cart for a group buy" do
    # Given a group buy product with variants and a distributor
    d = create(:distributor)
    p = create(:product, :distributors => [d], :group_buy => true)
    create(:variant, :product => p)

    # When I add the item to my cart
    visit spree.product_path p
    fill_in "quantity", :with => 2
    fill_in "max_quantity", :with => 3
    click_button 'Add To Cart'

    # Then the item should be in my cart with correct quantities
    order = Spree::Order.last
    li = order.line_items.first
    li.product.should == p
    li.quantity.should == 2
    li.max_quantity.should == 3
  end

  scenario "adding a product to cart that is not a group buy does not show max quantity field" do
    # Given a group buy product and a distributor
    d = create(:distributor)
    p = create(:product, :distributors => [d], :group_buy => false)

    # When I view the add to cart form, there should not be a max quantity field
    visit spree.product_path p

    page.should_not have_selector "#variant_attributes_#{p.master.id}_max_quantity"
  end

  scenario "adding a product with a max quantity less than quantity results in max_quantity==quantity" do
    # Given a group buy product and a distributor
    d = create(:distributor)
    p = create(:product, :distributors => [d], :group_buy => true)

    # When I add the item to my cart
    visit spree.product_path p
    fill_in "variants_#{p.master.id}", :with => 2
    fill_in "variant_attributes_#{p.master.id}_max_quantity", :with => 1
    click_button 'Add To Cart'

    # Then the item should be in my cart with correct quantities
    order = Spree::Order.last
    li = order.line_items.first
    li.product.should == p
    li.quantity.should == 2
    li.max_quantity.should == 2
  end

end
