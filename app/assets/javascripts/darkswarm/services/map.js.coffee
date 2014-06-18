Darkswarm.factory "OfnMap", (Enterprises, MapModal)->
  new class OfnMap
    constructor: ->
      @enterprises = (@extend(enterprise) for enterprise in Enterprises.enterprises) 


    # Adding methods to each enterprise
    extend: (enterprise)->
      new class MapMarker
        # We're whitelisting attributes because Gmaps tries to crawl
        # our data, and our data is recursive
        latitude: enterprise.latitude
        longitude: enterprise.longitude
        icon: enterprise.icon
        id: enterprise.id
        reveal: =>
          MapModal.open enterprise
