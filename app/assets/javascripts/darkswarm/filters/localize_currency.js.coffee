# Convert number to string currency using injected currency configuration.
#
# @requires currencyConfig json - /app/serializers/api/currency_config_serializer.rb
# @return: string
Darkswarm.filter "localizeCurrency", (currencyConfig)->
  (amount) ->
    currency_code = if currencyConfig.display_currency then " " + currencyConfig.currency else ""
    decimals = if currencyConfig.hide_cents == "true" then 0 else 2
    # We need to use parseFloat before toFixed as the amount should be a passed in as a string.
    amount_fixed = parseFloat(amount).toFixed(decimals)

    # Build the final price string.
    if currencyConfig.symbol_position == 'before'
      currencyConfig.symbol + amount_fixed + currency_code
    else
      amount_fixed + " " + currencyConfig.symbol + currency_code
