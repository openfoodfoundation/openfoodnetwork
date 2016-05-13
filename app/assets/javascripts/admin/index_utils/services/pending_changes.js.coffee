angular.module("admin.indexUtils").factory "pendingChanges", ($q, resources, StatusMessage) ->
  new class pendingChanges
    pendingChanges: {}
    errors: []

    add: (id, attr, change) =>
      @pendingChanges["#{id}"] = {} unless @pendingChanges.hasOwnProperty("#{id}")
      @pendingChanges["#{id}"]["#{attr}"] = change
      StatusMessage.display('notice', "You have made #{@changeCount(@pendingChanges)} unsaved changes")

    removeAll: =>
      @pendingChanges = {}

    remove: (id, attr) =>
      if @pendingChanges.hasOwnProperty("#{id}")
        delete @pendingChanges["#{id}"]["#{attr}"]
        delete @pendingChanges["#{id}"] if @changeCount( @pendingChanges["#{id}"] ) < 1

    submitAll: (form=null) =>
      all = []
      @errors = []
      StatusMessage.display('progress', "Saving...")
      for id, objectChanges of @pendingChanges
        for attrName, change of objectChanges
          all.push @submit(change)
      $q.all(all).then =>
        if @errors.length == 0
          StatusMessage.display('success', "All changes saved successfully")
          form.$setPristine() if form?
        else
          StatusMessage.display('failure', "Oh no! I was unable to save your changes")
      all

    submit: (change) ->
      resources.update(change).$promise.then (data) =>
        @remove change.object.id, change.attr
        change.scope.reset( data["#{change.attr}"] )
        change.scope.success()
      , (error) =>
        @errors.push error
        change.scope.error()

    changeCount: (objectChanges) ->
      Object.keys(objectChanges).length
