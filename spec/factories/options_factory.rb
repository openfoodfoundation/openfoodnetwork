# frozen_string_literal: true

FactoryBot.define do
  factory :option_value, class: Spree::OptionValue do
    name { 'Size' }
    presentation { 'S' }
    option_type
  end

  factory :option_type, class: Spree::OptionType do
    name { 'foo-size' }
    presentation { 'Size' }

    # Prevent inconsistent ordering in specs when all option types have the same (0) position
    sequence(:position)
  end
end
