# frozen_string_literal: true

class MultipleCheckedSelectComponent < ViewComponent::Base
  # @param id [String] uniquely identifies the MultipleCheckedSelect (mcs) field. '_mcs_field' will be appended
  def initialize(id:, name:, options:, selected:)
    @id = "#{id}_mcs_field"
    @name = name
    @options = options.map { |option| [option[0], option[1].to_sym] }
    @selected = selected.nil? ? [] : selected.map(&:to_sym)
  end
end
