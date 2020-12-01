# frozen_string_literal: false

require_dependency 'spree/calculator'
require 'spree/localized_number'

module Calculator
  class FlatPercentItemTotal < Spree::Calculator
    extend Spree::LocalizedNumber

    preference :flat_percent, :decimal, default: 0

    localize_number :preferred_flat_percent

    def self.description
      Spree.t(:flat_percent)
    end

    def compute(line_item)
      value = line_item.amount * BigDecimal(self.preferred_flat_percent.to_s) / 100.0
      (value * 100).round.to_f / 100
    end
  end
end
