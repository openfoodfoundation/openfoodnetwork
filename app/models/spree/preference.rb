# frozen_string_literal: true

module Spree
  class Preference < ApplicationRecord
    serialize :value

    validates :key, presence: true
    validates :value_type, presence: true

    scope :valid, -> {
      where(Spree::Preference.arel_table[:key].not_eq(nil)).
        where(Spree::Preference.arel_table[:value_type].not_eq(nil))
    }

    # The type conversions here should match
    # the ones in spree::preferences::preferrable#convert_preference_value
    def value
      if self[:value_type].present?
        case self[:value_type].to_sym
        when :string, :text
          self[:value].to_s
        when :password
          self[:value].to_s
        when :decimal
          BigDecimal(self[:value].to_s, exception: false)&.round(2, BigDecimal::ROUND_HALF_UP) ||
            self[:value]
        when :integer
          self[:value].to_i
        when :boolean
          !(self[:value].to_s =~ /^[t|1]/i).nil?
        else
          self[:value].is_a?(String) ? YAML.safe_load(self[:value]) : self[:value]
        end
      else
        self[:value]
      end
    end

    def raw_value
      self[:value]
    end
  end
end
