# frozen_string_literal: true

class MultipleCheckedSelectComponent < ViewComponent::Base
  renders_one :bottom_content

  def initialize(name:, options:, selected:)
    @name = name
    @options = options.map { |option| [option[0], identifier(option[1])] }
    @selected = selected.nil? ? [] : selected.map{ |s| identifier(s) }
  end

  def identifier(option)
    if option.is_a? Integer
      option
    else
      option.to_s.parameterize.underscore.to_sym
    end
  end
end
