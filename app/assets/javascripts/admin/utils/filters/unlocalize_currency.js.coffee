angular.module("admin.utils").filter "unlocalizeCurrency", ()->
  # Convert string to number using injected currency configuration.
  (price) ->
    if (!price)
      return null
    # used decimal and thousands separators from currency configuration
    decimal_separator = I18n.toCurrency(.1, {precision: 1, unit: ''}).substring(1,2)
    thousands_separator = I18n.toCurrency(1000, {precision: 1, unit: ''}).substring(1,2)

    if (price.length > 4)
      # remove configured thousands separator if price is greater than 999
      price = price.replaceAll(thousands_separator, '')
      
    if (decimal_separator == ",")
      price = price.replace(",", ".")

    return parseFloat(price)
