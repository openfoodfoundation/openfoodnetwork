Darkswarm.factory 'Hubs', ($filter, Enterprises, visibleFilter) ->
  new class Hubs
    constructor: ->
      @hubs = @order Enterprises.enterprises.filter (hub)->
        hub.has_hub_listing
      @visible = visibleFilter @hubs

    order: (hubs)->
      $filter('orderBy')(hubs, ['-active', '+orders_close_at'])
