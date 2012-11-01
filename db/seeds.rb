# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

require File.expand_path('../../spec/factories', __FILE__)


# -- Spree
unless Spree::Country.find_by_name 'Australia'
  puts "[db:seed] Seeding Spree"
  Spree::Core::Engine.load_seed if defined?(Spree::Core)
  Spree::Auth::Engine.load_seed if defined?(Spree::Auth)
end


# -- States
# States are created from factories instead of fixtures because models loaded from fixtures
# are not available to the app in the remainder of the seeding process (probably because of
# activerecord caching).
unless Spree::State.find_by_name 'Victoria'
  puts "[db:seed] Seeding states"

  [
   ['ACT', 'ACT'],
   ['New South Wales', 'NSW'],
   ['Northern Territory', 'NT'],
   ['Queensland', 'QLD'],
   ['South Australia', 'SA'],
   ['Tasmania', 'Tas'],
   ['Victoria', 'Vic'],
   ['Western Australia', 'WA']
  ].each do |state|

    # country_id 12 == Australia. See db/default/spree/countries.yaml
    FactoryGirl.create(:state, :name => state[0], :abbr => state[1], :country_id => 12)
  end
end


# -- Shipping / payment information
unless Spree::Zone.find_by_name 'Australia'
  puts "[db:seed] Seeding shipping / payment information"
  zone = FactoryGirl.create(:zone, :name => 'Australia', :zone_members => [])
  country = Spree::Country.find_by_name('Australia')
  Spree::ZoneMember.create(:zone => zone, :zoneable => country)
  FactoryGirl.create(:shipping_method, :zone => zone)
  FactoryGirl.create(:payment_method, :environment => 'development')
end


# -- Taxonomies
unless Spree::Taxonomy.find_by_name 'Products'
  puts "[db:seed] Seeding taxonomies"
  taxonomy = Spree::Taxonomy.find_by_name('Products') || FactoryGirl.create(:taxonomy, :name => 'Products')
  taxonomy_root = taxonomy.root

  ['Vegetables', 'Fruit', 'Oils', 'Preserves and Sauces', 'Dairy', 'Meat and Fish'].each do |taxon_name|
    FactoryGirl.create(:taxon, :name => taxon_name, :parent_id => taxonomy_root.id)
  end
end


# -- Enterprises
unless Enterprise.count > 0
  puts "[db:seed] Seeding enterprises"

  3.times { FactoryGirl.create(:supplier_enterprise) }
  3.times { FactoryGirl.create(:distributor_enterprise) }
end


# -- Products
unless Spree::Product.count > 0
  puts "[db:seed] Seeding products"

  FactoryGirl.create(:product,
                     :name => 'Garlic', :price => 20.00,
                     :supplier => Enterprise.is_primary_producer[0],
                     :distributors => [Enterprise.is_distributor[0]],
                     :taxons => [Spree::Taxon.find_by_name('Vegetables')])

  FactoryGirl.create(:product,
                     :name => 'Fuji Apple', :price => 5.00,
                     :supplier => Enterprise.is_primary_producer[1],
                     :distributors => Enterprise.is_distributor,
                     :taxons => [Spree::Taxon.find_by_name('Fruit')])

  FactoryGirl.create(:product,
                     :name => 'Beef - 5kg Trays', :price => 50.00,
                     :supplier => Enterprise.is_primary_producer[2],
                     :distributors => [Enterprise.is_distributor[2]],
                     :taxons => [Spree::Taxon.find_by_name('Meat and Fish')])
end
