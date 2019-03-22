FactoryBot.modify do
  factory :address do
    trait :randomized do
      firstname { Faker::Name.first_name }
      lastname { Faker::Name.last_name }
      address1 { Faker::Address.street_address }
      address2 nil
      phone { Faker::PhoneNumber.phone_number }
    end
  end
end
