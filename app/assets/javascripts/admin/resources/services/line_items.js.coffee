angular.module("admin.resources").factory 'LineItems', ($q, LineItemResource) ->
  new class LineItems
    byID: {}
    pristineByID: {}

    index: (params={}, callback=null) ->
    	LineItemResource.index params, (data) =>
        @load(data)
        (callback || angular.noop)(data)

    resetData: ->
      @byID = {}
      @pristineByID = {}

    load: (lineItems) ->
      @resetData()
      for lineItem in lineItems
        @byID[lineItem.id] = lineItem
        @pristineByID[lineItem.id] = angular.copy(lineItem)

    saveAll: ->
      for id, lineItem of @byID
        lineItem.errors = {} # removes errors when line_item has been returned to original state
        @save(lineItem) if !@isSaved(lineItem)

    save: (lineItem) ->
      deferred = $q.defer()
      lineItem.errors = {}
      lineItem.$update({id: lineItem.id})
      .then( (data) =>
        @pristineByID[lineItem.id] = angular.copy(lineItem)
        deferred.resolve(data)
      ).catch (response) ->
        lineItem.errors = response.data.errors if response.data.errors?
        deferred.reject(response)
      deferred.promise

    allSaved: ->
      for id, lineItem of @byID
        return false unless @isSaved(lineItem)
      true

    isSaved: (lineItem) ->
      @diff(lineItem).length == 0

    diff: (lineItem) ->
      changed = []
      for attr, value of lineItem when not angular.equals(value, @pristineByID[lineItem.id][attr])
        changed.push attr if attr in ["price", "quantity", "final_weight_volume"]
      changed

    resetAttribute: (lineItem, attribute) ->
      lineItem[attribute] = @pristineByID[lineItem.id][attribute]

    delete: (lineItem, callback=null) ->
      deferred = $q.defer()
      lineItem.$delete({id: lineItem.id})
      .then( (data) =>
        delete @byID[lineItem.id]
        delete @pristineByID[lineItem.id]
        (callback || angular.noop)(data)
        deferred.resolve(data)
      ).catch (response) ->
        deferred.reject(response)
      deferred.promise
