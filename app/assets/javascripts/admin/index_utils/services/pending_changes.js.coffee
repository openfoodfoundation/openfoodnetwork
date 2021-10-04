angular.module("admin.indexUtils").factory "pendingChanges", ($q, resources, StatusMessage) ->
  new class pendingChanges
    pendingChanges: {}
    errors: []

    add: (id, attr, change) =>
      @pendingChanges["#{id}"] = {} unless @pendingChanges.hasOwnProperty("#{id}")
      @pendingChanges["#{id}"]["#{attr}"] = change
      StatusMessage.display('notice', t('admin.unsaved_changes'))

    removeAll: =>
      @pendingChanges = {}
      StatusMessage.clear()


    remove: (id, attr) =>
      if @pendingChanges.hasOwnProperty("#{id}")
        delete @pendingChanges["#{id}"]["#{attr}"]
        delete @pendingChanges["#{id}"] if @changeCount( @pendingChanges["#{id}"] ) < 1

    submitAll: (form=null) =>
      all = []
      @errors = []
      StatusMessage.display('progress', t('js.saving'))
      for id, objectChanges of @pendingChanges
        for attrName, change of objectChanges
          all.push @submit(change)
      $q.all(all).then =>
        if @errors.length == 0
          StatusMessage.display('success', t('js.all_changes_saved_successfully'))
          form.$setPristine() if form?
        else
          StatusMessage.display('failure', t('js.oh_no'))
      .catch ->
        StatusMessage.display('failure', t('js.oh_no'))
      all

    submit: (change) ->
      resources.update(change).$promise.then (data) =>
        @remove change.object.id, change.attr
        change.scope.reset( data["#{change.attr}"] )
        change.scope.success()
      , (error) =>
        @errors.push error
        change.scope.error()

    unsavedCount: ->
      Object.keys(@pendingChanges).length

    changeCount: (objectChanges) ->
      Object.keys(objectChanges).length
