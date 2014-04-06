
require 'yaml'

require File.expand_path('../../../spec/factories', __FILE__)
require File.expand_path('../../../spec/support/spree/init', __FILE__)


unless Spree::Taxonomy.find_by_name 'Products'
  puts "Seeding taxonomies"
  taxonomy = Spree::Taxonomy.find_by_name('Products') || FactoryGirl.create(:taxonomy, :name => 'Products')
  taxonomy_root = taxonomy.root

  products = YAML::load_file 'db/seeds/products.yml'
  products.each do |taxon_name|
    FactoryGirl.create(:taxon, :name => taxon_name, :parent_id => taxonomy_root.id)
  end
else
  puts 'Taxonomies seeded!'
end

