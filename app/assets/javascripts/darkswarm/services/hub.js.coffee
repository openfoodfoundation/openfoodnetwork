Darkswarm.factory 'CurrentHub', ($location, $filter, currentHub) ->
  new class CurrentHub
    constructor: ->
        @[k] = v for k, v of currentHub
      
