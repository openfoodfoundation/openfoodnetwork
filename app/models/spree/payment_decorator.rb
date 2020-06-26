require 'spree/localized_number'

module Spree
  Payment.class_eval do
    delegate :line_items, to: :order

    # We bypass this after_rollback callback that is setup in Spree::Payment
    # The issues the callback fixes are not experienced in OFN:
    #   if a payment fails on checkout the state "failed" is persisted correctly
    def persist_invalid; end
  end
end
