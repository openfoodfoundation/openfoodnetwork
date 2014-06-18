Darkswarm.factory 'Hubs', ($filter, Enterprises) ->
  new class Hubs
    constructor: ->
      @hubs = @filter Enterprises.enterprises.filter (hub)->
        hub.type == "hub"
      

    filter: (hubs)->
      $filter('orderBy')(hubs, ['-active', '+orders_close_at'])
