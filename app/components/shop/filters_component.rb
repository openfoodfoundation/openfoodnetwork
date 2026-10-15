# frozen_string_literal: true

module Shop
  class FiltersComponent < ViewComponent::Base
    def initialize(properties:, url:, q:) # rubocop:disable Naming/MethodParameterName
      @properties = properties
      @url = url
      @q = q
    end
  end
end
