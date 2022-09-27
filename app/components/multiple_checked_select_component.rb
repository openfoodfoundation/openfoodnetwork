# frozen_string_literal: true

class MultipleCheckedSelectComponent < ViewComponent::Base
  def initialize(name:, options:, selected:, filter_placeholder: "Filter options")
    @name = name
    @filter_placeholder = filter_placeholder
    @options = options
    @selected = selected.map(&:to_sym)
  end
end
