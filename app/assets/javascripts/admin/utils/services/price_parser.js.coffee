angular.module("admin.utils").factory "PriceParser", ->
  new class PriceParser
    parse: (price) =>
      return null unless price
      # used decimal and thousands separators from currency configuration
      decimal_separator = I18n.toCurrency(.1, {precision: 1, unit: ''}).substring(1,2)
      thousands_separator = I18n.toCurrency(1000, {precision: 1, unit: ''}).substring(1,2)
      
      # Replace comma used as a decimal separator and remplace by "."
      price = this.replaceCommaByFinalPoint(price)

      # Remove configured thousands separator if it is actually a thousands separator
      price = this.removeThousandsSeparator(price, thousands_separator)

      if (decimal_separator == ",")
        price = price.replace(",", ".")

      price = parseFloat(price)

      return null if isNaN(price)

      return price

    replaceCommaByFinalPoint : (price) =>
      if price.match(/^[0-9]*(,{1})[0-9]{1,2}$/g) then price.replace(",", ".") else price

    removeThousandsSeparator : (price, thousands_separator) => 
      if (new RegExp("^([0-9]*(" + thousands_separator + "{1})[0-9]{3}[0-9\.,]*)*$", "g").test(price))
        price.replaceAll(thousands_separator, '')
      else
        price
