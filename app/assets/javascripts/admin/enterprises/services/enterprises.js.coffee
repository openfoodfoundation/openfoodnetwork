angular.module("admin.enterprises").factory 'Enterprises', ($q, EnterpriseResource) ->
  new class Enterprises
    enterprises: []
    enterprises_by_id: {}
    pristine_by_id: {}
    loaded: false

    index: (params={}, callback=null) ->
    	EnterpriseResource.index params, (data) =>
        for enterprise in data
          @enterprises.push enterprise
          @pristine_by_id[enterprise.id] = angular.copy(enterprise)

        @loaded = true
        (callback || angular.noop)(@enterprises)

    	@enterprises

    save: (enterprise) ->
      deferred = $q.defer()
      enterprise.$update({id: enterprise.permalink})
      .then( (data) =>
        @pristine_by_id[enterprise.id] = angular.copy(enterprise)
        deferred.resolve(data)
      ).catch (response) ->
        deferred.reject(response)
      deferred.promise

    saved: (enterprise) ->
      @diff(enterprise).length == 0

    diff: (enterprise) ->
      changed = []
      for attr, value of enterprise when not angular.equals(value, @pristine_by_id[enterprise.id][attr])
        changed.push attr unless attr is "$$hashKey"
      changed

    resetAttribute: (enterprise, attribute) ->
      enterprise[attribute] = @pristine_by_id[enterprise.id][attribute]
