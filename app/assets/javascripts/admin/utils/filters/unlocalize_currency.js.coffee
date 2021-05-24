angular.module("admin.utils").filter "unlocalizeCurrency", ()->
  # Convert string to number using injected currency configuration.
  (price) ->
    # used decimal separator from currency configuration
    decimal_separator = I18n.toCurrency(.1, {precision: 1, unit: ''}).substring(1,2)
    if (decimal_separator == ",")
      price = price.replace(",", ".")
    return parseFloat(price)
