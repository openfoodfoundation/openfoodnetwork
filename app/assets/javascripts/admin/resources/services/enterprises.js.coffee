angular.module("admin.resources").factory 'Enterprises', ($q, $filter, EnterpriseResource) ->
  new class Enterprises
    byID: {}
    pristineByID: {}

    index: (params={}, callback=null) ->
      EnterpriseResource.index params, (data) =>
        @load(data)
        (callback || angular.noop)(data)
        data

    load: (enterprises) ->
      for enterprise in enterprises
        @byID[enterprise.id] = enterprise
        @pristineByID[enterprise.id] = angular.copy(enterprise)

    save: (enterprise) ->
      deferred = $q.defer()
      enterprise.$update({id: enterprise.permalink})
      .then( (data) =>
        @pristineByID[enterprise.id] = angular.copy(enterprise)
        deferred.resolve(data)
      ).catch (response) ->
        deferred.reject(response)
      deferred.promise

    saved: (enterprise) ->
      @diff(enterprise).length == 0

    diff: (enterprise) ->
      changed = []
      for attr, value of enterprise when not angular.equals(value, @pristineByID[enterprise.id][attr])
        changed.push attr unless attr in @ignoredAttrs()
      changed

    ignoredAttrs: ->
      ["$$hashKey", "producer", "package", "producerError", "packageError", "status"]

    resetAttribute: (enterprise, attribute) ->
      enterprise[attribute] = @pristineByID[enterprise.id][attribute]

    performActionOnEnterpriseResource = (resourceAction) ->
      (enterprise) ->
        deferred = $q.defer()
        resourceAction({id: enterprise.permalink}, ((data) =>
          @pristineByID[enterprise.id] = angular.copy(data)
          deferred.resolve(data)
        ), ((response) ->
          deferred.reject(response)
        ))
        deferred.promise

    findByID: (id) ->
      @byID[id]

    # For finding multiple Enterprises represented by comma delimited string
    findByIDs: (ids) ->
      @byID[id] for id in ids.split(",") when @byID[id]

    findByTerm: (enterprises, term) ->
      $filter('filter')(enterprises, term)


    removeLogo: performActionOnEnterpriseResource(EnterpriseResource.removeLogo)
    removePromoImage: performActionOnEnterpriseResource(EnterpriseResource.removePromoImage)
