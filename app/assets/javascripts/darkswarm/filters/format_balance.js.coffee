angular.module('Darkswarm').filter "formatBalance", (localizeCurrencyFilter, tFilter)->
  # Convert number to string currency using injected currency configuration.
  (balance) ->
    if balance < 0
      tFilter('credit') + ": " + localizeCurrencyFilter(Math.abs(balance))
    else
      tFilter('balance_due') + ": " + localizeCurrencyFilter(Math.abs(balance))
