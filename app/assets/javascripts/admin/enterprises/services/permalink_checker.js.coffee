angular.module("admin.enterprises").factory 'PermalinkChecker', ($q, $http) ->
  new class PermalinkChecker
    deferredRequest: null
    deferredAbort: null
    MAX_PERMALINK_LENGTH: 255

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
      .then( (response) =>
        if response.data.length > @MAX_PERMALINK_LENGTH || !response.data.match(/^[\w-]+$/)
          deferredRequest.resolve
            permalink: permalink
            available: t('js.error')
        else
          deferredRequest.resolve
            permalink: response.data
            available: t('available')
      ).catch (response) =>
        if response.status == 409
          deferredRequest.resolve
            permalink: response.data
            available: t('js.unavailable')
        else
          # Something went wrong or request was aborted
          deferredRequest.reject()

      deferredRequest.promise.finally ->
        request = deferredRequest.promise = null

      deferredRequest.promise

    abort: (deferredAbort) ->
      deferredAbort.resolve()
