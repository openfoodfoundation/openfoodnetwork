angular.module("admin.order_cycles").filter "visibleProductVariants", ->
  return (product, exchange, rules) ->
    variants = product.variants.concat( [{ "id": product.master_id}] )
    return (variant for variant in variants when variant.id in rules[exchange.enterprise_id])
