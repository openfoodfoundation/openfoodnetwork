angular.module("admin.utils").filter "unlocalizeCurrency", ()->
  # Convert string to number using injected currency configuration.
  (price) ->
    if (!price)
      return null
    # used decimal and thousands separators from currency configuration
    decimal_separator = I18n.toCurrency(.1, {precision: 1, unit: ''}).substring(1,2)
    thousands_separator = I18n.toCurrency(1000, {precision: 1, unit: ''}).substring(1,2)
    
    # Replace comma used as a decimal separator and remplace by "."
    if (price.match(/^[0-9]*(,{1})[0-9]{1,2}$/g))
      price = price.replace(",", ".")

    # Remove configured thousands separator if it is actually a thousands separator
    if (new RegExp("^([0-9]*(" + thousands_separator + "{1})[0-9]{3}[0-9\.,]*)*$", "g").test(price))
      price = price.replaceAll(thousands_separator, '')

    if (decimal_separator == ",")
      price = price.replace(",", ".")

    price = parseFloat(price)

    if (isNaN(price))
      return null

    return price
