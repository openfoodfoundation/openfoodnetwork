Darkswarm.factory "OfnMap", (Enterprises, EnterpriseModal, visibleFilter)->
  new class OfnMap
    constructor: ->
      @enterprises = (@extend(enterprise) for enterprise in visibleFilter(Enterprises.enterprises))


    # Adding methods to each enterprise
    extend: (enterprise)->
      new class MapMarker
        # We're whitelisting attributes because GMaps tries to crawl
        # our data, and our data is recursive, so it breaks
        latitude: enterprise.latitude
        longitude: enterprise.longitude
        icon: enterprise.icon
        id: enterprise.id
        reveal: =>
          EnterpriseModal.open enterprise
