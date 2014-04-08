
require 'yaml'

require File.expand_path('../../../spec/factories', __FILE__)
require File.expand_path('../../../spec/support/spree/init', __FILE__)


states = YAML::load_file "db/seeds/#{OpenFoodNetwork::Config[:country_code]}/states.yml"

unless Spree::State.find_by_name states[0]['name']
  country = Spree::Country.find_by_name(OpenFoodNetwork::Config[:country])
  puts "[db:seed] Seeding states"

  states.each do |state|
    Spree::State.create!({"name"=>state['name'], "abbr"=>state['abbr'], :country=>country}, :without_protection => true)
  end
# else
#   puts "[db:seed] States already seeded"
end
