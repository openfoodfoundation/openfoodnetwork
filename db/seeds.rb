# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
require 'yaml'

# -- Spree
unless Spree::Country.find_by_iso(ENV['DEFAULT_COUNTRY_CODE'])
  puts "[db:seed] Seeding Spree"
  Spree::Core::Engine.load_seed if defined?(Spree::Core)
  Spree::Auth::Engine.load_seed if defined?(Spree::Auth)
end

country = Spree::Country.find_by_iso(ENV['DEFAULT_COUNTRY_CODE'])
puts "Country is #{country.to_s}"

puts "[db:seed] loading states yaml"
states = YAML::load_file "db/default/spree/states.yml"
puts "States: #{states.to_s}"

# -- Seeding States
puts "[db:seed] Seeding states for " + country.name

states.each do |state|
  puts "State: " + state.to_s

  unless Spree::State.find_by_name(state['name'])
    Spree::State.create!(
      { name: state['name'], abbr: state['abbr'], country: country },
      without_protection: true
    )
  end
end
