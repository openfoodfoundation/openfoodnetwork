angular.module("admin.indexUtils").factory "pendingChanges", (dataSubmitter) ->
  pendingChanges: {}

  add: (id, attr, change) ->
    @pendingChanges["#{id}"] = {} unless @pendingChanges.hasOwnProperty("#{id}")
    @pendingChanges["#{id}"]["#{attr}"] = change

  removeAll: ->
    @pendingChanges = {}

  remove: (id, attr) ->
    if @pendingChanges.hasOwnProperty("#{id}")
      delete @pendingChanges["#{id}"]["#{attr}"]
      delete @pendingChanges["#{id}"] if @changeCount( @pendingChanges["#{id}"] ) < 1

  submitAll: ->
    all = []
    for id, objectChanges of @pendingChanges
      for attrName, change of objectChanges
        all.push @submit(change)
    all

  submit: (change) ->
    dataSubmitter(change).then (data) =>
      @remove change.object.id, change.attr
      change.scope.reset( data["#{change.attr}"] )

  changeCount: (objectChanges) ->
    Object.keys(objectChanges).length
