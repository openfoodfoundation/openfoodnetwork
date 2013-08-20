require 'spec_helper'

feature %q{
    As a consumer
    I want to see product counts (for my chosen distributor) next to each taxon
    So that I can locate products (at my chosen distributor)
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    create(:distributor_enterprise, :name => "Edible garden")
  end

  # How should this work with distributors/order cycles?
  # - No distributor or OC selected - all shown
  # - Distributor selected - any from that distributor in any OC
  # - OC selected - any in that OC from any distributor
  # - Both selected - filter for both

  # Also keep specs for distributors outside order cycles.

  scenario "viewing product counts when no distributor or order cycle is selected", :future => true do
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

    # and proceed to the shop front
    click_on "Edible garden"

    # Then I should see product counts next to the taxons
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon one (1)'
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon two (2)'
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon three (3)'
  end


  scenario "viewing product counts when a distributor is selected", :future => true do
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

    p = create(:product, :taxons => [taxon_one])
    oc = create(:simple_order_cycle, distributors: [my_distributor], variants: [p.master])

    # When I visit the home page and select my distributor
    visit spree.select_distributor_order_path(my_distributor)
    within('nav#filters') { click_link my_distributor.name }
    page.should have_content 'You are shopping at My Distributor'

    # Then I should see distributor-scoped product counts next to the taxons
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon one (1)'
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon two (0)'
    page.should have_selector 'nav#taxonomies li', :text => 'Taxon three (2)'
  end


  describe "selecting an order cycle" do

    before(:each) do
      OrderCyclesHelper.class_eval do
        def order_cycles_enabled?
          true
        end
      end
    end

    scenario "viewing product counts when an order cycle is selected", :future => true do
      # Given some taxons and some products and some order cycles
      taxonomy = Spree::Taxonomy.find_by_name('Products') || create(:taxonomy, :name => 'Products')
      taxonomy_root = taxonomy.root

      taxon_one = create(:taxon, :name => 'Taxon one', :parent_id => taxonomy_root.id)
      taxon_two = create(:taxon, :name => 'Taxon two', :parent_id => taxonomy_root.id)
      taxon_three = create(:taxon, :name => 'Taxon three', :parent_id => taxonomy_root.id)

      supplier = create(:supplier_enterprise, :name => 'My Supplier')
      distributor = create(:distributor_enterprise, :name => 'My Distributor')

      t1p1 = create(:product, :taxons => [taxon_one], :distributors => [distributor])
      t2p1 = create(:product, :taxons => [taxon_two], :distributors => [distributor])
      t2p2 = create(:product, :taxons => [taxon_two], :distributors => [distributor])
      t3p1 = create(:product, :taxons => [taxon_three], :distributors => [distributor])
      t3p2 = create(:product, :taxons => [taxon_three], :distributors => [distributor])

      oc1 = create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor], variants: [t1p1.master, t2p1.master, t2p2.master])
      oc2 = create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor], variants: [t3p1.master, t3p2.master])

      # When I visit the home page and select my order cycle
      visit root_path
      click_on "Edible garden"
      choose oc2.name
      click_button 'Choose Order Cycle'
      page.should have_content 'Your order cycle has been selected.'

      # Then I should see order cycle-scoped product counts next to the taxons
      page.should have_selector 'nav#taxonomies li', :text => 'Taxon one (0)'
      page.should have_selector 'nav#taxonomies li', :text => 'Taxon two (0)'
      page.should have_selector 'nav#taxonomies li', :text => 'Taxon three (2)'
    end

    scenario "viewing product counts when both a distributor and an order cycle are selected", :future => true do
      # Given some taxons and some products under distributors
      taxonomy = Spree::Taxonomy.find_by_name('Products') || create(:taxonomy, :name => 'Products')
      taxonomy_root = taxonomy.root

      taxon_one = create(:taxon, :name => 'Taxon one', :parent_id => taxonomy_root.id)
      taxon_two = create(:taxon, :name => 'Taxon two', :parent_id => taxonomy_root.id)
      taxon_three = create(:taxon, :name => 'Taxon three', :parent_id => taxonomy_root.id)

      supplier = create(:supplier_enterprise, :name => 'My Supplier')
      my_distributor = create(:distributor_enterprise, :name => 'My Distributor')
      other_distributor = create(:distributor_enterprise, :name => 'Other Distributor')

      p1 = create(:product, :taxons => [taxon_one])
      p2 = create(:product, :taxons => [taxon_two])
      p3 = create(:product, :taxons => [taxon_three])
      p4 = create(:product, :taxons => [taxon_one])
      p5 = create(:product, :taxons => [taxon_two])

      oc1 = create(:simple_order_cycle, suppliers: [supplier])
      oc2 = create(:simple_order_cycle, suppliers: [supplier])
      create(:exchange, order_cycle: oc1, sender: oc1.coordinator, receiver: my_distributor, variants: [p1.master])
      create(:exchange, order_cycle: oc2, sender: oc2.coordinator, receiver: my_distributor, variants: [p2.master])
      create(:exchange, order_cycle: oc1, sender: oc1.coordinator, receiver: other_distributor, variants: [p3.master])
      create(:exchange, order_cycle: oc2, sender: oc2.coordinator, receiver: other_distributor, variants: [p4.master, p5.master])

      # When I visit the home page and select my distributor and order cycle
      visit spree.select_distributor_order_path(my_distributor)
      within('nav#filters') { click_link my_distributor.name }
      page.should have_content 'You are shopping at My Distributor'
      visit root_path
      click_on "Edible garden"
      choose oc2.name
      click_button 'Choose Order Cycle'
      page.should have_content 'Your order cycle has been selected.'

      # Then I should see distributor- and order-cycle-scoped product counts next to the taxons
      page.should have_selector 'nav#taxonomies li', :text => 'Taxon one (0)'
      page.should have_selector 'nav#taxonomies li', :text => 'Taxon two (1)'
      page.should have_selector 'nav#taxonomies li', :text => 'Taxon three (0)'
    end
  end
end
