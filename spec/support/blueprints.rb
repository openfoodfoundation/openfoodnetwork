require 'machinist/active_record'

# Add your blueprints here.
#
Spree::Supplier.blueprint do
  name        { "Supplier" }
  description { 'supplier ' }
  email       { 'email@somewhere.com' }
  twitter     { '' }
  website     { '' }
  address     { '4 McDougal Rd' }
  city        { 'Austinvale' }
  postcode    { '2312' }
  state       { Spree::State.find_by_name('Victoria') }
  country     { Spree::Country.find_by_name('Australia') }
end
