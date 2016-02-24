angular.module("admin.indexUtils").factory 'RequestMonitor', ($q) ->
  new class RequestMonitor
    loadQueue: $q.when([])
    loadId: 0
    loading: false

    load: (promise) ->
      loadId = (@loadId += 1)
      @loading = true
      @loadQueue = $q.all([@loadQueue, promise]).then =>
        @loading = false if @loadId == loadId
