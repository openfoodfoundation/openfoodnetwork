angular.module("admin.indexUtils").factory "dataFetcher", ($http, $q, RequestMonitor) ->
  return (dataLocation) ->
    deferred = $q.defer()
    RequestMonitor.load $http.get(dataLocation).then((response) ->
      deferred.resolve response.data
    ).catch ->
      deferred.reject()

    deferred.promise
