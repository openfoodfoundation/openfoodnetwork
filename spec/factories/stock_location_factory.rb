FactoryBot.define do
  factory :stock_location, class: Spree::StockLocation do
    # keeps the test stock_location unique
    initialize_with { Spree::StockLocation.first || DefaultStockLocation.find_or_create }

    address1 '1600 Pennsylvania Ave NW'
    city 'Washington'
    zipcode '20500'
    phone '(202) 456-1111'
    active true

    # sets the default value for variant.on_demand
    backorderable_default false

    country  { |stock_location| Spree::Country.first || stock_location.association(:country) }
    state do |stock_location|
      stock_location.country.states.first || stock_location.association(:state, :country => stock_location.country)
    end
  end
end
