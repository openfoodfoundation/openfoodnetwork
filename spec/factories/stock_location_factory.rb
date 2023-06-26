# frozen_string_literal: true

FactoryBot.define do
  factory :stock_location, class: Spree::StockLocation do
    # keeps the test stock_location unique
    initialize_with { Spree::StockLocation.first || DefaultStockLocation.find_or_create }

    address1 { '1600 Pennsylvania Ave NW' }
    city { 'Washington' }
    zipcode { '20500' }
    phone { '(202) 456-1111' }
    active { true }

    # sets the default value for variant.on_demand
    backorderable_default { false }

    country  { |stock_location| Spree::Country.first || stock_location.association(:country) }
    state do |stock_location|
      stock_location.country.states.first ||
        stock_location.association(:state, country: stock_location.country)
    end

    factory :stock_location_with_items do
      after(:create) do |stock_location, _evaluator|
        # variant will add itself to all stock_locations in an after_create
        # creating a product will automatically create a master variant
        product_1 = create(:product)
        product_2 = create(:product)

        stock_location.stock_items.where(variant_id: product_1.variants.first.id)
          .first.adjust_count_on_hand(10)
        stock_location.stock_items.where(variant_id: product_2.variants.first.id)
          .first.adjust_count_on_hand(20)
      end
    end
  end
end
