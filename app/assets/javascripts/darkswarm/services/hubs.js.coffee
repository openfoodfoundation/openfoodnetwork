Darkswarm.factory 'Hubs', ($filter, Enterprises) ->
  new class Hubs
    constructor: ->
      @hubs = @order Enterprises.enterprises.filter (hub)->
        hub.is_distributor

    order: (hubs)->
      $filter('orderBy')(hubs, ['-active', '+orders_close_at'])
