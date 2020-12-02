# frozen_string_literal: true

module Calculator
  class PercentOnLineItem < Spree::Calculator
    preference :percent, :decimal, default: 0

    def self.description
      Spree.t(:percent_per_item)
    end

    def compute(object)
      ((object.price * object.quantity) * preferred_percent) / 100
    end
  end
end
