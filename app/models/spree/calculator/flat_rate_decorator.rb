require 'spree/localized_number'

module Spree
  Calculator::FlatRate.class_eval do
    extend Spree::LocalizedNumber

    localize_number :preferred_amount

    def self.description
      I18n.t(:flat_rate_per_order)
    end
  end
end
