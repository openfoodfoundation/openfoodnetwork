# frozen_string_literal: true

module Spree
  class Property < ApplicationRecord
    has_many :product_properties, dependent: :destroy
    has_many :products, through: :product_properties
    has_many :producer_properties, dependent: :destroy

    after_touch :touch_producer_properties

    validates :name, :presentation, presence: true

    scope :sorted, -> { order(:name) }

    def property
      self
    end

    private

    def touch_producer_properties
      producer_properties.each(&:touch)
    end
  end
end
