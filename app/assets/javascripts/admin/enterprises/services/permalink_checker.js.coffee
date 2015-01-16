angular.module("admin.enterprises").factory 'PermalinkChecker', ($q, $http) ->
  new class PermalinkChecker
    check: (permalink) ->
      deferred = $q.defer()
      $http.get("/enterprises/check_permalink?permalink=#{permalink}", { headers: { 'Accept': 'application/javascript' } } )
      .success( (data) ->
        deferred.resolve data
      ).error (data) ->
        deferred.reject(data)

      deferred.promise
