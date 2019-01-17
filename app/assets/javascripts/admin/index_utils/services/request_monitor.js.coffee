angular.module("admin.indexUtils").factory 'RequestMonitor', ($q) ->
  new class RequestMonitor
    loadQueue: $q.when([])
    requestCount: 0
    loading: false

    load: (promise) ->
      @requestCount += 1
      @loading = true
      @loadQueue = $q.all([@loadQueue, promise]).then =>
        @requestCount -= 1
        @loading = false if @requestCount == 0
