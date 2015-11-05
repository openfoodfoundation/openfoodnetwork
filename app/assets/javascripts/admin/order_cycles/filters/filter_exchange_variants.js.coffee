angular.module("admin.orderCycles").filter "filterExchangeVariants", ->
  return (variants, rules) ->
    if variants? && rules?
      return (variant for variant in variants when variant in rules)
    else
      return []
