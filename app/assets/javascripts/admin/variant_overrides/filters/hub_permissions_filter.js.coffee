angular.module("admin.variantOverrides").filter "hubPermissions", ($filter) ->
  return (products, hubPermissions, hub_id) ->
    return [] if !hub_id
    return [] if !hubPermissions[hub_id]

    return $filter('filter')(products, ((product) ->
      for variant in product.variants
        return hubPermissions[hub_id].indexOf(variant.producer_id) > -1
     ), true)
