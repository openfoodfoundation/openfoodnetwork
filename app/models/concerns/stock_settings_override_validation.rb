# frozen_string_literal: true

# Validates the combination of on_demand and count_on_hand values.
#
# `on_demand` can have three values: true, false or nil
# `count_on_hand` can either be: nil or a number
#
# This means that a variant override can be in six different stock states
# but only three of them are valid.
#
# | on_demand | count_on_hand | stock_overridden? | use_producer_stock_settings? | valid? |
# |-----------|---------------|-------------------|------------------------------|--------|
# | 1         | nil           | false             | false                        | true   |
# | 0         | x             | true              | false                        | true   |
# | nil       | nil           | false             | true                         | true   |
# | 1         | x             | ?                 | ?                            | false  |
# | 0         | nil           | ?                 | ?                            | false  |
# | nil       | x             | ?                 | ?                            | false  |
#
# This module has one method for each invalid case.
module StockSettingsOverrideValidation
  extend ActiveSupport::Concern

  included do
    before_validation :require_compatible_on_demand_and_count_on_hand
  end

  def require_compatible_on_demand_and_count_on_hand
    disallow_count_on_hand_if_using_producer_stock_settings
    disallow_count_on_hand_if_on_demand
    require_count_on_hand_if_limited_stock
  end

  def disallow_count_on_hand_if_using_producer_stock_settings
    return unless on_demand.nil? && count_on_hand.present?

    error_message = I18n.t("count_on_hand.using_producer_stock_settings_but_count_on_hand_set",
                           scope: i18n_scope_for_stock_settings_override_validation_error)
    errors.add(:count_on_hand, error_message)
  end

  def disallow_count_on_hand_if_on_demand
    return unless on_demand? && count_on_hand.present?

    error_message = I18n.t("count_on_hand.on_demand_but_count_on_hand_set",
                           scope: i18n_scope_for_stock_settings_override_validation_error)
    errors.add(:count_on_hand, error_message)
  end

  def require_count_on_hand_if_limited_stock
    return unless on_demand == false && count_on_hand.blank?

    error_message = I18n.t("count_on_hand.limited_stock_but_no_count_on_hand",
                           scope: i18n_scope_for_stock_settings_override_validation_error)
    errors.add(:count_on_hand, error_message)
  end

  def i18n_scope_for_stock_settings_override_validation_error
    "activerecord.errors.models.#{self.class.name.underscore}"
  end
end
