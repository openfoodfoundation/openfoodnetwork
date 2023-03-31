# frozen_string_literal: true

module NestedCalculatorValidation
  extend ActiveSupport::Concern

  included do
    validates_associated :calculator, message: ->(class_obj, obj) {
      # Include all error messages from object
      obj[:value].errors.full_messages.join("; ")
    }
  end
end
