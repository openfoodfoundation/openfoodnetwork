angular.module("ofn.admin").factory "dataSubmitter", ($http, $q, resources) ->
  return (change) ->
    deferred = $q.defer()
    resources.update(change).$promise.then (data) ->
      change.scope.success()
      deferred.resolve data
    , ->
      change.scope.error()
      deferred.reject()
    deferred.promise
