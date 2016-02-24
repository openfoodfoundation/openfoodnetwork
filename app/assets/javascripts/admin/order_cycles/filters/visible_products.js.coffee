angular.module("admin.orderCycles").filter "visibleProducts", ($filter) ->
  return (products, exchange, rules) ->
    return (product for product in products when $filter('visibleProductVariants')(product, exchange, rules).length > 0)
