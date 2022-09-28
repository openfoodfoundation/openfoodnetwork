# frozen_string_literal: true

class MultipleCheckedSelectComponent < ViewComponent::Base
  def initialize(name:, options:, selected:, filter_placeholder: "Filter options")
    @name = name
    @filter_placeholder = filter_placeholder
    @options = options.map { |option| [option[0], option[1].to_sym] }
    @selected = selected.map(&:to_sym)
  end
end
