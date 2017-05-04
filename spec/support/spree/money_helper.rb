module Spree
  module MoneyHelper
    def with_currency(amount, options = {})
      Spree::Money.new(amount, {delimiter: ''}.merge(options)).to_s # Delimiter is to match js localizeCurrency
    end
  end
end
