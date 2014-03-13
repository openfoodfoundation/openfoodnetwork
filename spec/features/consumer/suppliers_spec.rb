require 'spec_helper'

feature %q{
    As a consumer
    I want to see a list of products from a supplier
    So that I can connect with them (and maybe buy stuff too)
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    create(:distributor_enterprise, :name => "Edible garden")
  end


  scenario "entering the site via a supplier's page" do
    # Given a supplier with some distributed products
    s = create(:supplier_enterprise)
    d = create(:distributor_enterprise)
    p = create(:simple_product, supplier: s) #, distributors: [d])
    oc = create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])

    # When I visit a supplier page
    visit enterprise_path(s)

    # Then I should see a list of hubs that distribute the suppliers products
    page.should have_link d.name

    # When I click on a hub
    click_link d.name

    # Then that hub should be selected
    page.should have_content d.name
  end

  scenario "viewing a list of suppliers (with active products) in the sidebar when there's 5 or fewer", :future => true do
    # Given some suppliers
    s1 = create(:supplier_enterprise)
    s2 = create(:supplier_enterprise)
    s3 = create(:supplier_enterprise)
    s4 = create(:supplier_enterprise)
    s5 = create(:supplier_enterprise)
    s6 = create(:supplier_enterprise)

    # And some of those suppliers have a product
    create(:product, :supplier => s1)
    create(:product, :supplier => s3, :on_hand => 0)

    # And no limit set for the sidebar
    sidebar_suppliers_limit = false

    # When I go to the home page
    visit spree.root_path

    # and proceed to the shop front
    click_on "Edible garden"

    # Then I should see a list containing all the suppliers that have active products in stock
    page.should have_selector 'a', :text => s1.name
    page.should_not have_selector 'a', :text => s2.name #has no products
    page.should_not have_selector 'a', :text => s3.name #has no products on hand

    # And I should see '5 more'
    suppliers_more = Enterprise.is_primary_producer.distinct_count - Enterprise.is_primary_producer.with_supplied_active_products_on_hand.limit(sidebar_suppliers_limit).length 
    page.should have_selector '#supplier_filter span.filter_more', :text => "#{suppliers_more} more"

    # And I should (always) see a browse suppliers button
    page.should have_selector "#supplier_filter input[value='Browse All Suppliers']"
  end

  scenario "viewing a list of all suppliers", :future => true do
    # Given some suppliers
    s1 = create(:supplier_enterprise)
    s2 = create(:supplier_enterprise)
    s3 = create(:supplier_enterprise)

    # And some of those suppliers have a product
    create(:product, :supplier => s1)
    create(:product, :supplier => s3)

    # When I go to the suppliers listing page
    visit spree.root_path
    click_on "Edible garden"
    click_button 'Browse All Suppliers'

    # Then I should see a list containing all the suppliers
    page.should have_selector '#content a', :text => s1.name
    page.should have_selector '#content a', :text => s2.name
    page.should have_selector '#content a', :text => s3.name
  end

  scenario "viewing products provided by a supplier", :future => true do
    # Given a supplier with a product
    s1 = create(:supplier_enterprise, :name => 'Murrnong', :long_description => "<p>Hello, world!</p>")
    p1 = create(:product, :supplier => s1)

    # And a different supplier with another product
    s2 = create(:supplier_enterprise, :name => 'Red Herring')
    p2 = create(:product, :supplier => s2)

    # When I select the first supplier
    visit spree.root_path
    click_on "Edible garden"
    click_link s1.name

    # Then I should see the supplier details
    page.should have_selector 'h2', :text => s1.name
    page.should have_selector 'div.enterprise-description', :text => 'Hello, world!'

    # And I should see the first, but not the second product
    page.should have_content p1.name
    page.should_not have_content p2.name
  end
end
