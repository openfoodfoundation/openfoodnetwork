angular.module("ofn.admin").factory "SpreeApiAuth", ($q, $http, SpreeApiKey) ->
  new class SpreeApiAuth
    authorise: ->
      deferred = $q.defer()

      $http.get("/api/users/authorise_api?token=" + SpreeApiKey)
      .success (response) ->
        if response?.success == "Use of API Authorised"
          $http.defaults.headers.common["X-Spree-Token"] = SpreeApiKey
          deferred.resolve()

      .error (response) ->
        error = response?.error || "You are unauthorised to access this page."
        deferred.reject(error)

      deferred.promise
