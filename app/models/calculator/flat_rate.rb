# frozen_string_literal: false

module Calculator
  class FlatRate < Spree::Calculator
    preference :amount, :decimal, default: 0

    validates :preferred_amount,
              numericality: true

    def self.description
      I18n.t(:flat_rate_per_order)
    end

    def compute(_object = nil)
      preferred_amount
    end
  end
end
