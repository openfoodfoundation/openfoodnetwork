# frozen_string_literal: true

FactoryBot.define do
  factory :address, aliases: [:bill_address, :ship_address], class: Spree::Address do
    firstname { 'John' }
    lastname { 'Doe' }
    company { 'unused' }
    address1 { '10 Lovely Street' }
    address2 { 'Northwest' }
    city { 'Herndon' }
    zipcode { '20170' }
    phone { '123-456-7890' }
    alternative_phone { '123-456-7899' }

    state { Spree::State.find_by(name: 'Victoria') || Spree::State.first || create(:state) }
    country do |address|
      if address.state
        address.state.country
      else
        Spree::Country.find_by(name: 'Australia') || Spree::Country.first || create(:country)
      end
    end

    trait :randomized do
      firstname { FFaker::Name.first_name }
      lastname { FFaker::Name.last_name }
      address1 { FFaker::Address.street_address }
      address2 { nil }
      phone { FFaker::PhoneNumber.phone_number }
      city { FFaker::Address.city }
      zipcode { FFaker::AddressUS.zip_code }
    end
  end
end
