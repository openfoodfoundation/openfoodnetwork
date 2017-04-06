angular.module("admin.reports").filter "customCurrency", ($filter, currencyConfig) ->
  return (value) ->
    value = 0 if !value
    if currencyConfig && currencyConfig.currency
      return currencyConfig.symbol + parseFloat(value).toFixed(2)
    else
      return parseFloat(value).toFixed(2)
