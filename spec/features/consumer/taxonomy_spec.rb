require 'spec_helper'

feature %q{
    As a consumer
    I want to see product counts (for my chosen distributor) next to each taxon
    So that I can locate products (at my chosen distributor)
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "viewing product counts when no distributor selected" do
    # Given some taxons and some products
    taxonomy = Spree::Taxonomy.find_by_name('Products') || create(:taxonomy, :name => 'Products')
    taxonomy_root = taxonomy.root

    taxon_one = create(:taxon, :name => 'Taxon one', :parent_id => taxonomy_root.id)
    taxon_two = create(:taxon, :name => 'Taxon two', :parent_id => taxonomy_root.id)
    taxon_three = create(:taxon, :name => 'Taxon three', :parent_id => taxonomy_root.id)

    1.times { create(:product, :taxons => [taxon_one]) }
    2.times { create(:product, :taxons => [taxon_two]) }
    3.times { create(:product, :taxons => [taxon_three]) }

    # When I visit the home page
    visit spree.root_path

    # Then I should see product counts next to the taxons
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon one (1)'
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon two (2)'
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon three (3)'
  end


  scenario "viewing product counts when a distributor is selected" do
    # Given some taxons and some products under distributors
    taxonomy = Spree::Taxonomy.find_by_name('Products') || create(:taxonomy, :name => 'Products')
    taxonomy_root = taxonomy.root

    taxon_one = create(:taxon, :name => 'Taxon one', :parent_id => taxonomy_root.id)
    taxon_two = create(:taxon, :name => 'Taxon two', :parent_id => taxonomy_root.id)
    taxon_three = create(:taxon, :name => 'Taxon three', :parent_id => taxonomy_root.id)

    my_distributor = create(:distributor_enterprise, :name => 'My Distributor')
    other_distributor = create(:distributor_enterprise, :name => 'Other Distributor')

    1.times { create(:product, :taxons => [taxon_one], :distributors => [other_distributor]) }
    2.times { create(:product, :taxons => [taxon_two], :distributors => [other_distributor]) }
    2.times { create(:product, :taxons => [taxon_three], :distributors => [other_distributor]) }
    2.times { create(:product, :taxons => [taxon_three], :distributors => [my_distributor]) }

    # When I visit the home page and select my distributor
    visit spree.select_distributor_order_path(my_distributor)
    click_link my_distributor.name
    page.should have_content 'You are shopping at My Distributor'

    # Then I should see distributor-scoped product counts next to the taxons
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon one (0)'
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon two (0)'
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon three (2)'
  end

end
