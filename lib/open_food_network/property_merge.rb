# frozen_string_literal: true

module OpenFoodNetwork
  class PropertyMerge
    def self.merge(primary, secondary)
      (primary + secondary).uniq do |property_object|
        property_object.property.presentation
      end
    end
  end
end
