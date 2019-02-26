angular.module("admin.utils").filter "localizeCurrency", (currencyConfig)->
  # Convert number to string currency using injected currency configuration.
  (amount) ->
    # Set country code (eg. "US").
    currency_code = if currencyConfig.display_currency then " " + currencyConfig.currency else ""
    # Set decimal points, 2 or 0 if hide_cents.
    decimals = if currencyConfig.hide_cents == "true" then 0 else 2
    # Set format if the currency symbol should come after the number, otherwise (default) use the locale setting.
    format = if currencyConfig.symbol_position == "after" then "%n %u" else undefined
    # We need to use parseFloat as the amount should come in as a string.
    amount = parseFloat(amount)

    # Build the final price string.
    I18n.toCurrency(amount, {precision: decimals, unit: currencyConfig.symbol, format: format}) + currency_code
