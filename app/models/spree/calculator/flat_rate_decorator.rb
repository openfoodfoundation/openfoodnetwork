require 'spree/localized_number'

module Spree
  Calculator::FlatRate.class_eval do
    extend Spree::LocalizedNumber

    localize_number :preferred_amount
  end
end
