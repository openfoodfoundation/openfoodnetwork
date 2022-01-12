angular.module('Darkswarm').factory 'Enterprises', (enterprises, ShopsResource, CurrentHub, Taxons, Dereferencer, Matcher, GmapsGeo, $rootScope) ->
  new class Enterprises
    enterprises: []
    enterprises_by_id: {}

    constructor: ->
      # Populate Enterprises.enterprises from json in page.
      @initEnterprises(enterprises)

    initEnterprises: (enterprises) ->
      # Map enterprises to id/object pairs for lookup.
      for enterprise in enterprises
        @enterprises.push enterprise
        @enterprises_by_id[enterprise.id] = enterprise

      # Replace enterprise and taxons ids with actual objects.
      @dereferenceEnterprises(enterprises)

      @producers = @enterprises.filter (enterprise)->
        enterprise.category in ["producer_hub", "producer_shop", "producer"]
      @hubs = @enterprises.filter (enterprise)->
        enterprise.category in ["hub", "hub_profile", "producer_hub", "producer_shop"]

    dereferenceEnterprises: (enteprises) ->
      if CurrentHub.hub?.id
        CurrentHub.hub = @enterprises_by_id[CurrentHub.hub.id]
      for enterprise in enterprises
        @dereferenceEnterprise enterprise

    dereferenceEnterprise: (enterprise) ->
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

    loadClosedEnterprises: ->
      request = ShopsResource.closed_shops {}, (data) =>
        @initEnterprises(data)

      request.$promise

    flagMatching: (query) ->
      for enterprise in @enterprises
        enterprise.matches_query = if query? && query.length > 0
          Matcher.match([enterprise.name, enterprise.address?.state_name, enterprise.address?.city], query)
        else
          false

    calculateDistance: (query, firstMatching) ->
      if query?.length > 0 and GmapsGeo.OK
        if firstMatching?
          @setDistanceFrom firstMatching
        else
          @calculateDistanceGeo query
      else
        @resetDistance()

    calculateDistanceGeo: (query) ->
      GmapsGeo.geocode query, (results, status) =>
        $rootScope.$apply =>
          if status == GmapsGeo.OK
            #console.log "Geocoded #{query} -> #{results[0].geometry.location}."
            @setDistanceFrom results[0].geometry.location
          else
            console.log "Geocoding failed for the following reason: #{status}"
            @resetDistance()

    setDistanceFrom: (locatable) ->
      for enterprise in @enterprises
        enterprise.distance = GmapsGeo.distanceBetween enterprise, locatable
      $rootScope.$broadcast 'enterprisesChanged'

    resetDistance: ->
      enterprise.distance = null for enterprise in @enterprises

    geocodedEnterprises: =>
      @enterprises.filter (enterprise) ->
        enterprise.latitude? && enterprise.longitude?

