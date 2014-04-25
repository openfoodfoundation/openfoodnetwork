Darkswarm.factory 'CurrentHub', ($location, hubs, $filter, currentHub) ->
  new class CurrentHub
    hasHub: false
    constructor: ->
        @[k] = v for k, v of currentHub
        @hasHub = true
      
