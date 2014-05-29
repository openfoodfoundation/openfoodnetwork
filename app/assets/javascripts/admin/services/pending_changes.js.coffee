angular.module("ofn.admin").factory "pendingChanges",[
  "dataSubmitter"
  (dataSubmitter) ->
    pendingChanges: {}

    add: (id, attrName, changeObj) ->
      @pendingChanges["#{id}"] = {} unless @pendingChanges.hasOwnProperty("#{id}")
      @pendingChanges["#{id}"]["#{attrName}"] = changeObj

    removeAll: ->
      @pendingChanges = {}

    remove: (id, attrName) ->
      if @pendingChanges.hasOwnProperty("#{id}")
        delete @pendingChanges["#{id}"]["#{attrName}"]
        delete @pendingChanges["#{id}"] if @changeCount( @pendingChanges["#{id}"] ) < 1

    submitAll: ->
      all = []
      for id,lineItem of @pendingChanges
        for attrName,changeObj of lineItem
          all.push @submit(id, attrName, changeObj)
      all

    submit: (id, attrName, change) ->
      dataSubmitter(change).then (data) =>
        @remove id, attrName
        change.element.dbValue = data["#{attrName}"]

    changeCount: (lineItem) ->
      Object.keys(lineItem).length
]