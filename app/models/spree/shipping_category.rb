# frozen_string_literal: true

module Spree
  class ShippingCategory < ApplicationRecord
    validates :name, presence: true
    has_many :products
    has_many :shipping_method_categories, inverse_of: :shipping_method
    has_many :shipping_methods, through: :shipping_method_categories
  end
end
