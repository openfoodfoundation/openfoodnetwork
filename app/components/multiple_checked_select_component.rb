# frozen_string_literal: true

class MultipleCheckedSelectComponent < ViewComponent::Base
  def initialize(name:, options:, selected:)
    @name = name
    @options = options.map { |option| [option[0], option[1].to_sym] }
    @selected = selected.nil? ? [] : selected.map(&:to_sym)
  end
end
