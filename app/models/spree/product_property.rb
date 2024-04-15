# frozen_string_literal: true

module Spree
  class ProductProperty < ApplicationRecord
    belongs_to :product, class_name: "Spree::Product", touch: true, optional: true
    belongs_to :property, class_name: 'Spree::Property'

    validates :value, length: { maximum: 255 }

    default_scope -> { order("#{table_name}.position") }

    # virtual attributes for use with AJAX completion stuff
    def property_name
      property&.name
    end

    def property_name=(name)
      return if name.blank?

      unless property = Property.find_by(name:)
        property = Property.create(name:, presentation: name)
      end
      self.property = property
    end
  end
end
