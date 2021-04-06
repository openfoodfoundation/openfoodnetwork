Darkswarm.filter "formatUnitPrice", (localizeCurrencyFilter) ->
  (price, unit) ->
    if price == null
      return null
    localizeCurrencyFilter(price) + "&nbsp;/&nbsp;" + unit
