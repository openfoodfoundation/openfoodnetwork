# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
require 'yaml'

# We need mail_configuration to create a user account, because it sends a confirmation email.
MailConfiguration.apply!

puts "[db:seed] Seeding Roles"
Spree::Role.where(:name => "admin").first_or_create
Spree::Role.where(:name => "user").first_or_create

puts "[db:seed] Seeding Countries"
unless Spree::Country.find_by(iso: ENV['DEFAULT_COUNTRY_CODE'])
  require File.join(File.dirname(__FILE__), 'default', 'countries')
end
country = Spree::Country.find_by(iso: ENV['DEFAULT_COUNTRY_CODE'])
puts "Default country is #{country.to_s}"

puts "[db:seed] Seeding states for " + country.name
states = YAML::load_file "db/default/spree/states.yml"
states.each do |state|
  puts "State: " + state.to_s
  unless Spree::State.find_by(name: state['name'])
    Spree::State.create!({ name: state['name'], abbr: state['abbr'], country: country })
  end
end

puts "[db:seed] Seeding Zones"
require File.join(File.dirname(__FILE__), 'default', 'zones')

puts "[db:seed] Seeding Users"
require File.join(File.dirname(__FILE__), 'default', 'users')

DefaultStockLocation.find_or_create
DefaultShippingCategory.find_or_create
