# Minimal test seeding
# --------------------
#
# Countries and states are seeded once in the beginning. The database cleaner
# leaves them there when deleting the rest (see spec/spec_helper.rb).
# You can add more entries here if you need them for your tests.

if Spree::Country.scoped.empty?
  Spree::Country.create!({"name"=>"Australia", "iso3"=>"AUS", "iso"=>"AU", "iso_name"=>"AUSTRALIA", "numcode"=>"36"}, :without_protection => true)
  country = Spree::Country.find_by_name('Australia')
  Spree::State.create!({"name"=>"Victoria", "abbr"=>"Vic", :country=>country}, :without_protection => true)
  Spree::State.create!({"name"=>"New South Wales", "abbr"=>"NSW", :country=>country}, :without_protection => true)
end

# Since the country seeding differs from other environments, the default
# country id has to be updated here. This line can be removed as soon as the
# default country id is replaced by something database independent.
Spree::Config.default_country_id = Spree::Country.find_by_name('Australia').id
