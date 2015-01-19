angular.module("admin.enterprises").factory 'PermalinkChecker', ($q, $http) ->
  new class PermalinkChecker
    deferredRequest: null
    deferredAbort: null

    check: (permalink) =>
      @abort(@deferredAbort) if @deferredRequest && @deferredRequest.promise
      @deferredRequest = deferredRequest = $q.defer()
      @deferredAbort = deferredAbort = $q.defer()
      request = $http(
        method:   "GET"
        url:      "/enterprises/check_permalink?permalink=#{permalink}"
        headers:
          Accept: 'application/javascript'
        timeout: deferredAbort.promise
      )
      .success( (data) =>
        deferredRequest.resolve
          permalink: data
          available: "Available"
      ).error (data,status) =>
        if status == 409
          deferredRequest.resolve
            permalink: data
            available: "Unavailable"
        else
          # Something went wrong or request was aborted
          deferredRequest.reject()

      deferredRequest.promise.finally ->
        request = deferredRequest.promise = null;

      deferredRequest.promise

    abort: (deferredAbort) ->
      deferredAbort.resolve()
