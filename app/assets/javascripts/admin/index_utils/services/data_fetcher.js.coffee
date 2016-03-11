angular.module("admin.indexUtils").factory "dataFetcher", ($http, $q, RequestMonitor) ->
  return (dataLocation) ->
    deferred = $q.defer()
    RequestMonitor.load $http.get(dataLocation).success((data) ->
      deferred.resolve data
    ).error ->
      deferred.reject()

    deferred.promise
