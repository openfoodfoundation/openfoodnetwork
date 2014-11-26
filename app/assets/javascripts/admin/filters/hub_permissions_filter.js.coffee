angular.module("ofn.admin").filter "hubPermissions", ($filter) ->
  return (products, hubPermissions, hub_id) ->
    return [] if !hub_id
    return $filter('filter')(products, ((product) -> hubPermissions[hub_id].indexOf(product.producer_id) > -1), true)
