# frozen_string_literal: true

module PaypalRest
  module MoneyBuilder
    private

    def money(value, currency)
      {
        currency_code: currency,
        value: format("%.2f", value)
      }
    end
  end
end
