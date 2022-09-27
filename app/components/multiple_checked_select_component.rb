# frozen_string_literal: true

class MultipleCheckedSelectComponent < ViewComponent::Base
  def initialize(name:, options:, selected:)
    @name = name
    @options = options
    @selected = selected.map(&:to_sym)
  end
end
