# frozen_string_literal: true

class SearchInputComponent < ViewComponentReflex::Component
  def initialize(value: nil, data: {})
    super
    @value = value
    @data = data
  end
end
