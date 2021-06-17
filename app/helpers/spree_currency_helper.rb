# frozen_string_literal: true

module SpreeCurrencyHelper
  def spree_number_to_currency(amount)
    Spree::Money.new(amount).to_s
  end
end
