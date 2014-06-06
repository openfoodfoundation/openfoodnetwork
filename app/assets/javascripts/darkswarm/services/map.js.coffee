Darkswarm.factory "OfnMap", (enterprisesForMap, MapModal)->
  new class OfnMap
    constructor: ->
      @enterprises = (@extend(enterprise) for enterprise in enterprisesForMap)

    # Adding methods to each enterprise
    extend: (enterprise)->
      new class MapMarker
        icon: "/test.opng"
        constructor: ->
          @[k] = v for k, v of enterprise

        reveal: =>

          console.log @
          MapModal.open @
