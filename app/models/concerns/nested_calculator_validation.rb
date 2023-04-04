# frozen_string_literal: true

module NestedCalculatorValidation
  extend ActiveSupport::Concern

  included do
    validates_associated :calculator
    after_validation :remove_calculator_error
  end

  def remove_calculator_error
    # Remove generic calculator message, in favour of messages provided by validates_associated
    errors.delete(:calculator) if errors.key?(:calculator)
  end
end
