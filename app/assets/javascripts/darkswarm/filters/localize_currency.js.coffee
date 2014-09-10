# Convert number to string currency using injected currency localisation settings.
#
# @requires currencyConfig json - /app/serializers/api/currency_localization_serializer.rb
# @return string
Darkswarm.filter "localizeCurrency", (currencyConfig)->
  (amount) ->
    decimals = if currencyConfig.hide_cents then 0 else 2
    amount_fixed = amount.toFixed(2)
    currency_str = ""
    currency_str = " " + currencyConfig.currency if currencyConfig.display_currency

    # Return: string. Varies with symbol position.
    if currencyConfig.symbol_position == 'before'
      currencyConfig.symbol + amount_fixed + currency_str
    else
      amount_fixed + " " + currencyConfig.symbol + currency_str

