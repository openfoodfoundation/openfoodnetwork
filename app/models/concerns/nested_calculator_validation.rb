# frozen_string_literal: true

module NestedCalculatorValidation
  extend ActiveSupport::Concern

  included do
    validate :associated_calculator
  end

  def associated_calculator
    # Calculator errors have already been added, don't know why.
    errors.each do |error|
      errors.delete(error.attribute) if error.attribute.match? /^calculator./
    end
    # Copy errors from associated calculator to the base object, prepending "calculator." to the attribute name.
    # wait a minute, that's what the messages were before! we just needed to get the translate keys right!
    calculator.tap(&:valid?).errors.each do |error|
      errors.import error, attribute: [:calculator, error.attribute].join('.')
    end
  end
end
