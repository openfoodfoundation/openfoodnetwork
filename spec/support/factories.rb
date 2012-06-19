require 'faker'
require 'spree/core/testing_support/factories'

FactoryGirl.define do
  factory :supplier, :class => Spree::Supplier do
    sequence(:name) { |n| "Supplier #{n}" }
    description 'supplier'
    email       'supplier@example.com'
    address     '4 McDougal Rd'
    city        'Austinvale'
    postcode    '2312'
    state       Spree::State.find_by_name('Victoria')
    country     Spree::Country.find_by_name('Australia')
  end

  factory :distributor, :class => Spree::Distributor do
    sequence(:name) { |n| "Distributor #{n}" }
    contact        "Mr Turing"
    phone          "1000100100"
    description    'The creator'
    email          'alan@somewhere.com'
    pickup_address 'Wilmslow'
    pickup_times   "Whenever you're free"
    city           'Cheshire'
    post_code      '2312'
    state          Spree::State.find_by_name('Victoria')
    country        Spree::Country.find_by_name('Australia')
  end
end


FactoryGirl.modify do
  factory :simple_product do
    distributors { [Spree::Distributor.first || FactoryGirl.create(:distributor)] }
  end
end
