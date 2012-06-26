require 'faker'
require 'spree/core/testing_support/factories'

FactoryGirl.define do
  factory :supplier, :class => Spree::Supplier do
    sequence(:name) { |n| "Supplier #{n}" }
    description 'supplier'
    email       'supplier@example.com'
    address { Spree::Address.first || FactoryGirl.create(:address) }
  end

  factory :distributor, :class => Spree::Distributor do
    sequence(:name) { |n| "Distributor #{n}" }
    contact        "Mr Turing"
    phone          "1000100100"
    description    'The creator'
    email          'alan@somewhere.com'
    pickup_times   "Whenever you're free"
    pickup_address { Spree::Address.first || FactoryGirl.create(:address) }
  end
end


FactoryGirl.modify do
  factory :simple_product do
    supplier { Spree::Supplier.first || FactoryGirl.create(:supplier) }
    distributors { [Spree::Distributor.first || FactoryGirl.create(:distributor)] }
  end
end
