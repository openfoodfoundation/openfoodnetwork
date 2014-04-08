
require 'csv'
require 'yaml'

require File.expand_path('../../../spec/factories', __FILE__)
require File.expand_path('../../../spec/support/spree/init', __FILE__)

suburbs_file = "db/seeds/#{OpenFoodNetwork::Config[:country_code]}/suburbs.csv"
states = YAML::load_file "db/seeds/#{OpenFoodNetwork::Config[:country_code]}/states.yml"

states_ids = {}
states.each { |s| states_ids[s['abbr']] = Spree::State.where(abbr: s['abbr']).first.id }

statement = "INSERT INTO suburbs (postcode,name,state_id,latitude,longitude) VALUES\n"
CSV.foreach(suburbs_file) do |row|
  postcode = row[0]
  name = row[1]
  state_id = states_ids[row[2]]
  lat = row[3]
  long = row[4]
  statement += "(#{postcode},$$#{name}$$,#{state_id},#{lat},#{long}),"
end
statement[-1] = ';'
# puts statement

connection = ActiveRecord::Base.connection()
connection.execute(statement)
