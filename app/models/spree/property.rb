module Spree
  class Property < ActiveRecord::Base
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
