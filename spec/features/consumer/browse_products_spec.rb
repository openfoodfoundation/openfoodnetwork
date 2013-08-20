require 'spec_helper'

feature %q{
    As a consumer
    I want to browse products by distributor and order cycle
    So that I can buy products that are available soon and close to me
} do
  include AuthenticationWorkflow
  include WebHelper

  describe "selecting a distributor" do
    it "displays the distributor's details" do
      # Given a distributor with a product
      d = create(:distributor_enterprise, :name => 'Melb Uni Co-op', :description => '<p>Hello, world!</p>')
      create(:product, :distributors => [d])

      # When I select the distributor
      visit spree.select_distributor_order_path(d)

      # Then I should see the name of the distributor that I've selected
      page.should have_selector 'h2', :text => 'Melb Uni Co-op'

      # And I should see the distributor's long description
      page.should have_selector 'div.enterprise-description', :text => 'Hello, world!'
    end

    it "displays the distributor's name on the home page" do
      # Given a distributor with a product
      d = create(:distributor_enterprise, :name => 'Melb Uni Co-op', :description => '<p>Hello, world!</p>')
      p1 = create(:product, :distributors => [d])

      # When I select the distributor
      visit spree.select_distributor_order_path(d)
      visit spree.root_path
      click_on "Melb Uni Co-op"

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

      # When I select the first distributor
      visit spree.select_distributor_order_path(d1)
      visit spree.root_path

      # Then I should see products split by local/remote distributor
      # on the home page, the products page, the search results page and the taxon page
      [spree.products_path,
       spree.products_path(:keywords => 'Product'),
       spree.nested_taxons_path(taxon.permalink)
      ].each do |path|

        visit path
        page.should_not have_selector '#products'
        page.should have_selector '#products-local', :text => p1.name
        page.should have_selector '#products-remote', :text => p2.name
      end
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

        # When we select the distributor without the product and then view the product
        visit spree.select_distributor_order_path(distributor_no_product)
        visit spree.root_path
        visit spree.product_path(product)

        # Then we should be told that our distributor will be set to the one with the product
        page.should_not have_selector "select#distributor_id"
        page.should have_content "our distributor for this order will be changed to #{distributor_product.name} if you add this product to your cart."
      end
    end
  end

  describe "selecting an order cycle" do

    before(:each) do
      OrderCyclesHelper.class_eval do
        def order_cycles_enabled?
          true
        end
      end
    end

    it "displays the distributor and order cycle name on the home page when an order cycle is selected" do
      # Given a distributor with a product
      d = create(:distributor_enterprise, :name => 'Melb Uni Co-op')
      p = create(:product)
      oc = create(:simple_order_cycle, :name => 'Bulk Foods', :distributors => [d], :variants => [p.master])

      # When I select the distributor and order cycle
      visit spree.product_path p
      select d.name, :from => 'distributor_id'
      select oc.name, :from => 'order_cycle_id'
      click_button 'Add To Cart'

      # Then I should see the name of the distributor and order cycle that I've selected
      page.should have_content 'You are shopping at Melb Uni Co-op in Bulk Foods'
      page.should_not have_selector 'div.distributor-description'
    end

    it "splits the product listing by local/remote order cycle" do
      # Given two order cycles, with a product under each, and each product under a taxon
      taxonomy = Spree::Taxonomy.find_by_name('Products') || create(:taxonomy, :name => 'Products')
      taxonomy_root = taxonomy.root
      taxon = create(:taxon, :name => 'Taxon one', :parent_id => taxonomy_root.id)
      d1 = create(:distributor_enterprise, :name => "Melb Uni Co-op")
      d2 = create(:distributor_enterprise)
      p1 = create(:product, :taxons => [taxon])
      p2 = create(:product, :taxons => [taxon])
      oc1 = create(:simple_order_cycle, distributors: [d1], variants: [p1.master])
      oc2 = create(:simple_order_cycle, distributors: [d2], variants: [p2.master])

      # When I select the first order cycle
      visit spree.root_path
      click_on "Melb Uni Co-op"
      choose oc1.name
      click_button 'Choose Order Cycle'

      # Then I should see the products split by local/remote order cycle
      # on the home page, the products page, the search results page and the taxon page
      [spree.products_path,
       spree.products_path(:keywords => 'Product'),
       spree.nested_taxons_path(taxon.permalink)
      ].each do |path|

        visit path
        page.should_not have_selector '#products'
        page.should have_selector '#products-local', :text => p1.name
        page.should have_selector '#products-remote', :text => p2.name
      end
    end
  end
end
