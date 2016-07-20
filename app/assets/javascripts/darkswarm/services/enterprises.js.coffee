Darkswarm.factory 'Enterprises', (enterprises, CurrentHub, Taxons, Dereferencer, visibleFilter, Matcher, Geo, $rootScope) ->
  new class Enterprises
    enterprises_by_id: {}
    constructor: ->
      # Populate Enterprises.enterprises from json in page.
      @enterprises = enterprises
      # Map enterprises to id/object pairs for lookup.
      for enterprise in enterprises
        @enterprises_by_id[enterprise.id] = enterprise
      # Replace enterprise and taxons ids with actual objects.
      @dereferenceEnterprises()
      @visible_enterprises = visibleFilter @enterprises
      @producers = @visible_enterprises.filter (enterprise)->
        enterprise.category in ["producer_hub", "producer_shop", "producer"]
      @hubs = @visible_enterprises.filter (enterprise)->
        enterprise.category in ["hub", "hub_profile", "producer_hub", "producer_shop"]

    dereferenceEnterprises: ->
      if CurrentHub.hub?.id
        CurrentHub.hub = @enterprises_by_id[CurrentHub.hub.id]
      for enterprise in @enterprises
        @dereferenceEnterprise enterprise

    dereferenceEnterprise: (enterprise) ->
      @dereferenceProperty(enterprise, 'hubs', @enterprises_by_id)
      @dereferenceProperty(enterprise, 'producers', @enterprises_by_id)
      @dereferenceProperty(enterprise, 'taxons', Taxons.taxons_by_id)
      @dereferenceProperty(enterprise, 'supplied_taxons', Taxons.taxons_by_id)

    dereferenceProperty: (enterprise, property, data) ->
      # keep unreferenced enterprise ids
      # in case we dereference again after adding more enterprises
      enterprise.unreferenced |= {}
      collection = enterprise[property]
      unreferenced = enterprise.unreferenced[property] || collection
      enterprise.unreferenced[property] =
        Dereferencer.dereference_from unreferenced, collection, data

    addEnterprises: (new_enterprises) ->
      return unless new_enterprises && new_enterprises.length
      for enterprise in new_enterprises
        @enterprises_by_id[enterprise.id] = enterprise

    flagMatching: (query) ->
      for enterprise in @enterprises
        enterprise.matches_name_query = if query? && query.length > 0
          Matcher.match([enterprise.name], query)
        else
          false

    calculateDistance: (query, firstMatching) ->
      if query?.length > 0
        if firstMatching?
          @setDistanceFrom firstMatching
        else
          @calculateDistanceGeo query
      else
        @resetDistance()

    calculateDistanceGeo: (query) ->
      Geo.geocode query, (results, status) =>
        $rootScope.$apply =>
          if status == Geo.OK
            #console.log "Geocoded #{query} -> #{results[0].geometry.location}."
            @setDistanceFrom results[0].geometry.location
          else
            console.log "Geocoding failed for the following reason: #{status}"
            @resetDistance()

    setDistanceFrom: (locatable) ->
      for enterprise in @enterprises
        enterprise.distance = Geo.distanceBetween enterprise, locatable
      $rootScope.$broadcast 'enterprisesChanged'

    resetDistance: ->
      enterprise.distance = null for enterprise in @enterprises
