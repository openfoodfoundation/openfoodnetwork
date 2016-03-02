angular.module("admin.orderCycles").filter "visibleVariants", ->
  return (variants, exchange, rules) ->
    return (variant for variant in variants when variant.id in rules[exchange.enterprise_id])
