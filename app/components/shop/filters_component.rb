# frozen_string_literal: true

module Shop
  class FiltersComponent < ViewComponent::Base
    def initialize(properties:)
      @properties = properties
    end
  end
end
