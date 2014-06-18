Darkswarm.factory "OfnMap", (enterprisesForMap, MapModal)->
  new class OfnMap
    constructor: ->
      @enterprises = (@extend(enterprise) for enterprise in enterprisesForMap)
      console.log @enterprises

    # Adding methods to each enterprise
    extend: (enterprise)->
      new class MapMarker
        constructor: ->
          @[k] = v for k, v of enterprise
        reveal: =>
          MapModal.open @
