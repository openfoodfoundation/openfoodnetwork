angular.module("ofn.admin").filter "keywords", ($filter) ->
  return (array, query) ->
    return array unless query
    keywords = query.split ' '
    keywords.forEach (key) ->
      array = $filter('filter')(array, key)
    array
