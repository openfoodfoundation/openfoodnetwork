# Used like a regular angular filter where an object is passed
# Adds the additional special case that a value of 0 for the filter
# acts as a bypass for that particular attribute

# NOTE the name doesn't reflect what the filter does, it only fiters on the variant.producer_id
angular.module("admin.indexUtils").filter "attrFilter", ($filter) ->
  return (objects, filters) ->
    filter = filters["producer_id"]

    return objects if !filter? || filter == 0

    return $filter('filter')(objects, (product) ->
      for variant in product.variants
        return true if variant["producer_id"] == filter
      false
    , true)
