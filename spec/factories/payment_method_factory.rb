FactoryBot.define do
  factory :payment_method, class: Spree::PaymentMethod::Check do
    name 'Check'
    environment 'test'

    distributors { [Enterprise.is_distributor.first || FactoryBot.create(:distributor_enterprise)] }
  end

  factory :bogus_payment_method, class: Spree::Gateway::Bogus do
    name 'Credit Card'
    environment 'test'
  end
end
