# frozen_string_literal: true

class Shop::FiltersComponent < ViewComponent::Base
  def initialize(properties:, url:, q:)
    @properties = properties
    @url = url
    @q = q
  end
end
