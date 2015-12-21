Darkswarm.factory 'Orders', (orders, CurrentHub, Taxons, Dereferencer, visibleFilter, Matcher, Geo, $rootScope)->
  new class Orders
    orders_by_distributor: {}
    distributor_names_by_id: {}
    constructor: ->
      # Populate Orders.orders from json in page.
      @orders = orders
      # Organise orders by distributor.
      for order in orders
        if order.distributor?
          if @orders_by_distributor[order.distributor.id]? then @orders_by_distributor[order.distributor.id].push order else @orders_by_distributor[order.distributor.id] = [order]
          if !@distributor_names_by_id[order.distributor.id] then @distributor_names_by_id[order.distributor.id] = {name: order.distributor.name, balance: 0}
      for id in Object.keys(@distributor_names_by_id)
        @distributor_names_by_id[id].balance = @orders_by_distributor[id].reduce(((x,y) ->
          x + Number(y.outstanding_balance)), 0).toFixed(2)
      console.log @distributor_names_by_id


      # Sorting by most orders (most recent/frequent?)
