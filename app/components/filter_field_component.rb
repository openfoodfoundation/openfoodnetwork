# frozen_string_literal: true

class FilterFieldComponent < ViewComponent::Base
  attr_reader :title, :open, :options, :selected

  def initialize(title:, open:, options:, selected:)
    super()
    @title = title
    @open = open
    @options = options
    @selected = selected
  end
end
