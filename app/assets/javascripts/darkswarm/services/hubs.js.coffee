Darkswarm.factory 'Hubs', (hubs, $filter) ->
  new class Hubs
    constructor: ->
      @hubs = $filter('orderBy')(hubs, ['-active', '+orders_close_at'])
