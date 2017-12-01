require 'spree/localize_number'

module Spree
  Calculator::FlatRate.class_eval do
    extend Spree::LocalizeNumber

    localize_number :preferred_amount
  end
end
