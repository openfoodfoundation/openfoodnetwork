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

    # And some of those distributors are in an order cycle
    create(:simple_order_cycle, :distributors => [d1, d2])

    # When I go to the home page
    visit spree.root_path

    # Then I should see a list containing the distributors that are in the order cycle
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
    create(:simple_order_cycle, :distributors => [d1, d2])

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


  context "when a distributor is selected" do
    it "displays the distributor's details" do
      # Given a distributor with a product
      d = create(:distributor_enterprise, :name => 'Melb Uni Co-op', :description => '<p>Hello, world!</p>')
      create(:product, :distributors => [d])
      create(:simple_order_cycle, :distributors => [d])

      # When I select the distributor
      visit spree.root_path
      click_link d.name

      # Then I should see the name of the distributor that I've selected
      page.should have_selector 'h2', :text => 'Melb Uni Co-op'

      # And I should see the distributor's long description
      page.should have_selector 'div.enterprise-description', :text => 'Hello, world!'
    end

    it "displays the distributor's name on the home page" do
      # Given a distributor with a product
      d = create(:distributor_enterprise, :name => 'Melb Uni Co-op', :description => '<p>Hello, world!</p>')
      p1 = create(:product, :distributors => [d])
      create(:simple_order_cycle, :distributors => [d])

      # When I select the distributor
      visit spree.select_distributor_order_path(d)
      visit spree.root_path

      # Then I should see the name of the distributor that I've selected
      page.should have_content 'You are shopping at Melb Uni Co-op'
      page.should_not have_selector 'div.distributor-description'
    end

    it "splits the product listing by local/remote distributor" do
      # Given two distributors, with a product under each, and each product under a taxon
      taxonomy = Spree::Taxonomy.find_by_name('Products') || create(:taxonomy, :name => 'Products')
      taxonomy_root = taxonomy.root
      taxon = create(:taxon, :name => 'Taxon one', :parent_id => taxonomy_root.id)
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      p1 = create(:product, :distributors => [d1], :taxons => [taxon])
      p2 = create(:product, :distributors => [d2], :taxons => [taxon])
      create(:simple_order_cycle, :distributors => [d1, d2])

      # When I select the first distributor
      visit spree.select_distributor_order_path(d1)
      visit spree.root_path

      # Then I should see products split by local/remote distributor
      # on the home page, the products page, the search results page and the taxon page
      [spree.root_path,
       spree.products_path,
       spree.products_path(:keywords => 'Product'),
       spree.nested_taxons_path(taxon.permalink)
      ].each do |path|

        visit path
        page.should_not have_selector '#products'
        page.should have_selector '#products-local', :text => p1.name
        page.should have_selector '#products-remote', :text => p2.name
      end
    end

    it "allows the user to leave the distributor" do
      # Given a distributor with a product
      d = create(:distributor_enterprise, :name => 'Melb Uni Co-op')
      p1 = create(:product, :distributors => [d])
      create(:simple_order_cycle, :distributors => [d])

      # When I select the distributor and then leave it
      visit spree.select_distributor_order_path(d)
      visit spree.root_path
      click_button 'Browse All Distributors'

      # Then I should have left the distributor
      page.should_not have_selector '#current-distributor', :text => 'You are shopping at Melb Uni Co-op'
    end

    context "viewing a product, it provides a choice of distributor when adding to cart" do
      it "works when no distributor is chosen" do
        # Given a distributor and a product under it
        distributor = create(:distributor_enterprise)
        product = create(:product, :distributors => [distributor])

        # When we view the product
        visit spree.product_path(product)

        # Then we should see a choice of distributor, with no default
        page.should have_selector "select#distributor_id option", :text => distributor.name
        page.should_not have_selector "select#distributor_id option[selected='selected']"
      end

      it "displays the local distributor as the default choice when available for the current product" do
        # Given a distributor and a product under it
        distributor1 = create(:distributor_enterprise)
        distributor2 = create(:distributor_enterprise)
        product = create(:product, :distributors => [distributor1,distributor2])

        # When we select the distributor and view the product
        visit spree.select_distributor_order_path(distributor1)
        visit spree.product_path(product)

        # Then we should see our distributor as the default option when adding the item to our cart
        page.should have_selector "select#distributor_id option[value='#{distributor1.id}'][selected='selected']"
      end

      it "works when viewing a product from a remote distributor" do
        # Given two distributors and our product under one
        distributor_product = create(:distributor_enterprise)
        distributor_no_product = create(:distributor_enterprise)
        product = create(:product, :distributors => [distributor_product])
        create(:product, :distributors => [distributor_no_product])
        create(:simple_order_cycle, :distributors => [distributor_product, distributor_no_product])

        # When we select the distributor without the product and then view the product
        visit spree.root_path
        click_link distributor_no_product.name
        visit spree.product_path(product)

        # Then we should see a choice of distributor,
        # with no default and no option for the distributor that the product does not belong to
        page.should     have_selector "select#distributor_id option", :text => distributor_product.name
        page.should_not have_selector "select#distributor_id option", :text => distributor_no_product.name
        page.should_not have_selector "select#distributor_id option[selected='selected']"
      end
    end
  end
end
