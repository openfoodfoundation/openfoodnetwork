require 'spec_helper'

feature %q{
    As a consumer
    I want to see a list of distributors
    So that I can shop by a particular distributor
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "viewing a list of distributors in the sidebar", :future => true do
    # Given some distributors
    d1 = create(:distributor_enterprise, :name => "Edible garden")
    d2 = create(:distributor_enterprise)
    d3 = create(:distributor_enterprise)

    # And some of those distributors have a product
    create(:product, :distributors => [d1, d2])

    # When I go to the home page
    visit spree.root_path

    # and proceed to the shop front
    click_on "Edible garden"

    # Then I should see a list containing the distributors that have products
    page.should have_selector 'a', :text => d1.name
    page.should have_selector 'a', :text => d2.name
    page.should_not have_selector 'a', :text => d3.name
  end

  scenario "viewing a list of distributors (with active products) in the sidebar when there's some inactive distributors", :future => true do
    # Given some distributors
    d1 = create(:distributor_enterprise, :name => "Edible garden")
    d2 = create(:distributor_enterprise)
    d3 = create(:distributor_enterprise)
    d4 = create(:distributor_enterprise)
    d5 = create(:distributor_enterprise)
    d6 = create(:distributor_enterprise)

    # And some of those distributors have a product
    create(:product, :distributors => [d1])
    create(:product, :distributors => [d3], :on_hand => 0)

    # And no limit set for the sidebar
    sidebar_distributors_limit = false

    # When I go to the home page
    visit spree.root_path

    # and proceed to the shop front
    click_on "Edible garden"

    # Then I should see a list containing all the distributors that have active products in stock
    page.should have_selector 'a', :text => d1.name
    page.should_not have_selector 'a', :text => d2.name #has no products
    page.should_not have_selector 'a', :text => d3.name #has no products on hand

    # And I should see '5 more'
    distributors_more = Enterprise.is_distributor.distinct_count - Enterprise.is_distributor.with_distributed_active_products_on_hand.by_name.limit(sidebar_distributors_limit).length 
    page.should have_selector '#distributor_filter span.filter_more', :text => "#{distributors_more} more"

    # And I should (always) see a browse distributors button
    page.should have_selector "#distributor_filter input[value='Browse All Distributors']"
  end

  scenario "viewing a list of all distributors", :future => true do
    # Given some distributors
    d1 = create(:distributor_enterprise, :name => "Edible garden")
    d2 = create(:distributor_enterprise)
    d3 = create(:distributor_enterprise)

    # And some of those distributors have a product
    create(:product, :distributors => [d1])
    create(:product, :distributors => [d3])

    # When I go to the distributors listing page
    visit spree.root_path
    click_on "Edible garden"
    click_button 'Browse All Distributors'

    # Then I should see a list containing all the distributors
    page.should have_selector '#content a', :text => d1.name
    page.should have_selector '#content a', :text => d2.name
    page.should have_selector '#content a', :text => d3.name
  end


  scenario "viewing a distributor", :js => true do
    # Given some distributors with products
    d1 = create(:distributor_enterprise, :name => "Edible garden", :long_description => "<p>Hello, world!</p>")
    d2 = create(:distributor_enterprise)
    p1 = create(:product, :distributors => [d1])
    p2 = create(:product, :distributors => [d2])
    supplier = create(:supplier_enterprise)
    order_cycle = create(:simple_order_cycle, suppliers: [supplier], distributors: [d1], variants: [p1.master])

    # When I go to the first distributor page
    visit spree.root_path
    click_link d1.name

    # And when I choose an order cycle
    select_by_value order_cycle.id, :from => 'order_order_cycle_id'

    # Then I should see the distributor details
    page.should have_selector 'h1', :text => d1.name
    page.should have_selector 'div.enterprise-description', :text => 'Hello, world!'

    # And I should see the first, but not the second product
    page.should have_content p1.name
    page.should_not have_content p2.name
  end
end
