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
      page.should have_selector 'h1', :text => 'Melb Uni Co-op'

      # And I should see the distributor's long description
      page.should have_selector 'div.enterprise-description', :text => 'Hello, world!'
    end

    it "displays the distributor's name on the home page" do
      # Given a distributor with a product
      d = create(:distributor_enterprise, :name => 'Melb Uni Co-op', :description => '<p>Hello, world!</p>')
      create_enterprise_group_for d
      p1 = create(:product, :distributors => [d])

      # When I select the distributor
      visit spree.select_distributor_order_path(d)
      visit spree.root_path
      click_on "Melb Uni Co-op"

      # Then I should see the name of the distributor that I've selected
      page.should have_content 'Melb Uni Co-op'
      page.should_not have_selector 'div.distributor-description'
    end

    it "splits the product listing by local/remote distributor", :future => true do
      # Given two distributors, with a product under each, and each product under a taxon
      taxonomy = Spree::Taxonomy.find_by_name('Products') || create(:taxonomy, :name => 'Products')
      taxonomy_root = taxonomy.root
      taxon = create(:taxon, :name => 'Taxon one', :parent_id => taxonomy_root.id)
      d1 = create(:distributor_enterprise, :name => 'Green Grass')
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
        page.should have_selector '#products'
      end
    end

    describe "variant listing" do
      it "shows only variants that are in the distributor and order cycle", js: true do
        # Given a product with two variants
        s = create(:supplier_enterprise)
        d = create(:distributor_enterprise, name: 'Green Grass')
        create_enterprise_group_for d
        p = create(:simple_product, supplier: s)
        v1 = create(:variant, product: p, is_master: false)
        v2 = create(:variant, product: p, is_master: false)

        # And only one of those is distributed by an order cycle
        oc = create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [v1])

        # When I am in that order cycle
        visit root_path
        click_link d.name

        # And I view the product
        click_link p.name

        # Then I should see only the relevant variant
        page.all('#product-variants li input').count.should == 1
      end
    end
  end
end
