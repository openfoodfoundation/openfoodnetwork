# frozen_string_literal: true

# Minimal test seeding
# --------------------
#
# Countries and states are seeded once in the beginning. The database cleaner
# leaves them there when deleting the rest (see spec/spec_helper.rb).
# You can add more entries here if you need them for your tests.
#
# Every record is seeded on its own so that a partially seeded database is
# completed instead of being left in an inconsistent state.

{
  { "name" => "Australia", "iso3" => "AUS", "iso" => "AU",
    "iso_name" => "AUSTRALIA", "numcode" => "36" } => [
      { "name" => "Victoria", "abbr" => "Vic" },
      { "name" => "New South Wales", "abbr" => "NSW" },
    ],
  { "name" => "France", "iso3" => "FRA", "iso" => "FR",
    "iso_name" => "FRANCE", "numcode" => "250" } => [
      { "name" => "Alsace", "abbr" => "Als" },
      { "name" => "Aquitaine", "abbr" => "Aq" },
    ],
}.each do |country_attributes, states|
  country = Spree::Country.find_or_create_by!(name: country_attributes["name"]) do |new_country|
    new_country.attributes = country_attributes
  end

  states.each do |state_attributes|
    Spree::State.find_or_create_by!(name: state_attributes["name"], country:) do |new_state|
      new_state.abbr = state_attributes["abbr"]
    end
  end
end
