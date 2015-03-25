angular.module("admin.order_cycles").filter "visibleVariants", ->
  return (product, exchange, rules) ->
    enterprise_id = if exchange.incoming then exchange.sender_id else exchange.receiver_id
    return (variant for variant in product.variants when variant.id in rules[exchange.enterprise_id])
