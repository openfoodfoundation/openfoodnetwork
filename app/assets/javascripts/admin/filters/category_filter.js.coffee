angular.module("ofn.admin").filter "category", ($filter) ->
  return (products, taxonID) ->
    return products if taxonID == "0"
    return $filter('filter')( products, { category_id: taxonID }, true )