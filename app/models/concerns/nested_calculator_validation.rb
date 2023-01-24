# frozen_string_literal: true

module NestedCalculatorValidation
  extend ActiveSupport::Concern

  included do
    validates_associated :calculator
    after_validation :set_custom_error_messages, if: :calculator_errors?
  end

  def calculator_errors?
    calculator.errors.any?
  end

  def set_custom_error_messages
    add_custom_error_messages
    delete_generic_error_message
    delete_preferred_value_errors
  end

  def add_custom_error_messages
    calculator.errors.messages&.each do |attribute, msgs|
      msgs.each do |msg|
        errors.add(:base, "#{localize_calculator_attributes[attribute]}: #{msg}")
      end
    end
  end

  def delete_generic_error_message
    errors.delete(:calculator) if errors[:calculator] && errors[:calculator][0] == "is invalid"
  end

  def delete_preferred_value_errors
    calculator.preferences.each do |k, _v|
      errors.delete("calculator.preferred_#{k}".to_sym )
    end
  end

  def localize_calculator_attributes
    {
      preferred_amount: I18n.t('spree.amount'),
      preferred_flat_percent: I18n.t('spree.flat_percent'),
      preferred_first_item: I18n.t('spree.first_item'),
      preferred_additional_item: I18n.t('spree.additional_item'),
      preferred_max_items: I18n.t('spree.max_items'),
      preferred_normal_amount: I18n.t('spree.normal_amount'),
      preferred_discount_amount: I18n.t('spree.discount_amount'),
      preferred_minimal_amount: I18n.t('spree.minimal_amount'),
    }
  end
end
