# frozen_string_literal: true

module Spree
  class Property < ApplicationRecord
    has_many :product_properties, dependent: :destroy
    has_many :products, through: :product_properties
    has_many :producer_properties

    validates :name, :presentation, presence: true

    scope :sorted, -> { order(:name) }

    def property
      self
    end
  end
end
