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

end
