# frozen_string_literal: true

FactoryBot.define do
  factory :taxon, class: Spree::Taxon do
    name { 'Ruby on Rails' }
  end
end
