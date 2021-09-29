angular.module("admin.orderCycles").filter "visibleVariants", ->
  return (variants, exchange, rules) ->
    enterprise_rules = rules[exchange.enterprise_id]
    if enterprise_rules
      (variant for variant in variants when variant.id in enterprise_rules)
    else
      []
