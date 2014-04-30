
require 'csv'
require 'yaml'

require File.expand_path('../../../spec/factories', __FILE__)
require File.expand_path('../../../spec/support/spree/init', __FILE__)

suburbs_file = File.join ['db', 'seeds', OpenFoodNetwork::Config.country_code.downcase, 'suburbs.csv']
states = YAML::load_file File.join ['db', 'seeds', OpenFoodNetwork::Config.country_code.downcase, 'states.yml']

country = Spree::Country.where(iso: OpenFoodNetwork::Config.country_code.upcase!).first
states_ids = {}
states.each { |s| states_ids[s['abbr']] = Spree::State.where(abbr: s['abbr']).where(country_id: country.id).first.id }

name = ''
statement = "INSERT INTO suburbs (postcode,name,state_id,latitude,longitude) VALUES\n"
CSV.foreach(suburbs_file, {headers: true, header_converters: :symbol}) do |row|
  postcode = row[:postcode]
  name = row[:name]
  state_id = states_ids[row[:state_id]]
  lat = row[:latitude]
  long = row[:longitude]
  statement += "(#{postcode},$$#{name}$$,#{state_id},#{lat},#{long}),"
end
statement[-1] = ';'
# puts statement

unless Suburb.find_by_name(name)
  puts "[db:seed] Seeding suburbs for " + OpenFoodNetwork::Config.country_code
  connection = ActiveRecord::Base.connection()
  connection.execute(statement)
else
  puts '[db:seed] Suburbs seeded!'
end
