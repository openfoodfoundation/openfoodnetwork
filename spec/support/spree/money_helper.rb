module Spree
  module MoneyHelper
    def currency
      Spree::Money.currency_symbol
    end
  end
end
