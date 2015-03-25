angular.module("admin.order_cycles").filter "visibleProducts", ($filter) ->
  return (products, exchange, rules) ->
    return (product for product in products when $filter('visibleVariants')(product, exchange, rules).length > 0)
