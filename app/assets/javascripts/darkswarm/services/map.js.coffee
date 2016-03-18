Darkswarm.factory "OfnMap", (Enterprises, EnterpriseModal, visibleFilter) ->
  new class OfnMap
    constructor: ->
      @enterprises = @enterprise_markers(Enterprises.enterprises)
      @enterprises = @enterprises.filter (enterprise) ->
        enterprise.latitude != null || enterprise.longitude != null # Remove enterprises w/o lat or long

    enterprise_markers: (enterprises) ->
      @extend(enterprise) for enterprise in visibleFilter(enterprises)

    # Adding methods to each enterprise
    extend: (enterprise) ->
      new class MapMarker
        # We cherry-pick attributes because GMaps tries to crawl
        # our data, and our data is cyclic, so it breaks
        latitude: enterprise.latitude
        longitude: enterprise.longitude
        icon: enterprise.icon
        id: enterprise.id
        reveal: =>
          EnterpriseModal.open enterprise
