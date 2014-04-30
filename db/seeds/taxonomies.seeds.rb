
require 'yaml'

require File.expand_path('../../../spec/factories', __FILE__)
require File.expand_path('../../../spec/support/spree/init', __FILE__)

taxonomies = YAML::load_file File.join ['db', 'seeds', 'taxonomies.yml']
print taxonomies

unless Spree::Taxonomy.find_by_name(taxonomies[0]['name'])
  puts "[db:seed] Seeding taxonomies"
  taxonomies.each do |taxonomy|
    taxonomy_obj = Spree::Taxonomy.find_by_name(taxonomy['name']) || FactoryGirl.create(:taxonomy, :name => taxonomy['name'])
    taxonomy_root = taxonomy_obj.root

    taxonomy['terms'].each do |taxon_name|
      FactoryGirl.create(:taxon, :name => taxon_name, :parent_id => taxonomy_root.id)
    end
  end
else
  puts '[db:seed] Taxonomies seeded!'
end

