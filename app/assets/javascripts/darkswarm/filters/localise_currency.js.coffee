# Convert number to string currency using injected currency localisation settings.
#
# Injected: currencyLocalisation - see /app/serializers/api/currency_localization_serializer.rb

Darkswarm.filter "localiseCurrency", (currencyLocalization)->
  (amount) ->
    decimals = if currencyLocalization.hide_cents then 0 else 2
    amount_fixed = amount.toFixed(decimals)
    currency_str = ""
    currency_str = " " + currencyLocalization.currency if currencyLocalization.display_currency

    # Return string
    if currencyLocalization.symbol_position == 'before'
      currencyLocalization.symbol + amount_fixed + currency_str
    else
      amount_fixed + " " + currencyLocalization.symbol + currency_str

