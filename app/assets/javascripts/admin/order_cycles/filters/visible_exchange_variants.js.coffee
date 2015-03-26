angular.module("admin.order_cycles").filter "visibleExchangeVariants", ->
  return (variants, exchange, rules) ->
    return (variant for variant in variants when variant in rules[exchange.enterprise_id])
