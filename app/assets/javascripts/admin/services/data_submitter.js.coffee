angular.module("ofn.admin").factory "dataSubmitter", [
  "$http", "$q", "switchClass"
  ($http, $q, switchClass) ->
    return (changeObj) ->
      deferred = $q.defer()
      $http.put(changeObj.url).success((data) ->
        switchClass changeObj.element, "update-success", ["update-pending", "update-error"], 3000
        deferred.resolve data
      ).error ->
        switchClass changeObj.element, "update-error", ["update-pending", "update-success"], false
        deferred.reject()
      deferred.promise
]