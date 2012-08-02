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
    sequence(:name)    { |n| "Distributor #{n}" }
    contact            'Mr Turing'
    phone              '1000100100'
    description        'The creator'
    email              'alan@somewhere.com'
    url                'http://example.com'
    pickup_times       "Whenever you're free"
    next_collection_at 'Thursday 10am'
    pickup_address     { Spree::Address.first || FactoryGirl.create(:address) }
  end

  factory :product_distribution, :class => Spree::ProductDistribution do
    product         { |pd| Spree::Product.first        || FactoryGirl.create(:product) }
    distributor     { |pd| Spree::Distributor.first    || FactoryGirl.create(:distributor) }
    shipping_method { |pd| Spree::ShippingMethod.first || FactoryGirl.create(:shipping_method) }
  end

  factory :itemwise_shipping_method, :parent => :shipping_method do
    name 'Delivery'
    calculator { FactoryGirl.build(:itemwise_calculator) }
  end

  factory :itemwise_calculator, :class => OpenFoodWeb::Calculator::Itemwise do
  end
end


FactoryGirl.modify do
  factory :simple_product do
    supplier { Spree::Supplier.first || FactoryGirl.create(:supplier) }
    on_hand 3

    # before(:create) do |product, evaluator|
    #   product.product_distributions = [FactoryGirl.create(:product_distribution, :product => product)]
    # end
  end

  factory :address do
    state { Spree::State.find_by_name 'Victoria' }
    country { Spree::Country.find_by_name 'Australia' || Spree::Country.first }
  end
end
