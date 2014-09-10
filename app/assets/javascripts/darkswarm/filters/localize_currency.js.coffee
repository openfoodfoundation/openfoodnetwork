# Convert number to string currency using injected currency configuration.
#
# @requires currencyConfig json - /app/serializers/api/currency_config_serializer.rb
# @return: string
Darkswarm.filter "localizeCurrency", (currencyConfig)->
  (amount) ->
    decimals = if currencyConfig.hide_cents then 0 else 2
    amount_fixed = amount.toFixed(2)
    currency_str = ""
    currency_str = " " + currencyConfig.currency if currencyConfig.display_currency

    if currencyConfig.symbol_position == 'before'
      currencyConfig.symbol + amount_fixed + currency_str
    else
      amount_fixed + " " + currencyConfig.symbol + currency_str

