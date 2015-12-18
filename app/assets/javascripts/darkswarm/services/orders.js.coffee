Darkswarm.factory 'Orders', (orders, CurrentHub, Taxons, Dereferencer, visibleFilter, Matcher, Geo, $rootScope)->
  new class Orders
    orders_by_distributor: {}
    distributors = []
    constructor: ->
      # Populate Orders.orders from json in page.
      @orders = orders
      # Organise orders by distributor.
      for order in orders
        if order.distributor?.id
          @orders_by_distributor[order.distributor.name] = order
      # Can we guarantee order of keys in js?
      @distributors = Object.keys(@orders_by_distributor)
      # Sorting by most orders (most recent/frequent?)
