angular.module("ofn.admin").factory "dataSubmitter", ($http, $q) ->
  return (change) ->
    deferred = $q.defer()
    url = "/api/orders/#{change.object.order.number}/line_items/#{change.object.id}?line_item[#{change.attr}]=#{change.value}"
    $http.put(url).success((data) ->
      change.scope.success()
      deferred.resolve data
    ).error ->
      change.scope.error()
      deferred.reject()
    deferred.promise
