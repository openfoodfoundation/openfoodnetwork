# Used like a regular angular filter where an object is passed
# Adds the additional special case that a value of 0 for the filter
# acts as a bypass for that particular attribute
angular.module("admin.indexUtils").filter "attrFilter", ($filter) ->
  return (objects, filters) ->
    Object.keys(filters).reduce (filtered, attr) ->
      filter = filters[attr]
      return filtered if !filter? || filter == 0
      return $filter('filter')(filtered, (object) ->
        object[attr] == filter
      )
    , objects
