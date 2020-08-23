FactoryBot.define do
  factory :shipping_category, class: Spree::ShippingCategory do   
    initialize_with { DefaultShippingCategory.find_or_create }
    transient { name 'Default' }
    sequence(:name) { |n| "ShippingCategory ##{n}" }
  end
end
