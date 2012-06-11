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

Spree::Distributor.blueprint do
  name        { "Distributor" }
  contact     { "Mr Turing"}
  phone       { "1000100100" }
  description { 'The creator' }
  email       { 'alan@somewhere.com' }
  pickup_address { 'Wilmslow' }
  pickup_times{ "Whenever you're free" }
  city        { 'Cheshire' }
  post_code   { '2312' }
  state       { Spree::State.find_by_name('Victoria') }
  country     { Spree::Country.find_by_name('Australia') }
end

Spree::Product.blueprint do
  name        { "Apples" }
  description { 'Tasty apples' }
  available_on{ Date.today - 2.days }
  count_on_hand { 5 }
  price       { 10.99 }
end

Spree::Variant.blueprint do
  sku        { "12345" }
  price      { 10.99 }
  cost_price { 10.99 }
end

Spree::Zone.blueprint do
  name        {"Australia"}
  description {"Australia"}
  default_tax { true }
end

Spree::ShippingMethod.blueprint do
  name        {"Eeaterprises"}
  calculator_type { 'Spree::Calculator::FlatPercentItemTotal' }
end

Spree::PaymentMethod.blueprint do
  name        { "Bogus " }
  description { "" }
  environment { "test" }
  type        { "Spree::Gateway::BogusSimple" }
  active      { true }
end
