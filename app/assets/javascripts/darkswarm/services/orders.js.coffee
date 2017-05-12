Darkswarm.factory 'Orders', (orders_by_distributor, currencyConfig, CurrentHub, Taxons, Dereferencer, visibleFilter, Matcher, Geo, $rootScope)->
  new class Orders
    constructor: ->
      # Populate Orders.orders from json in page.
      @orders_by_distributor = orders_by_distributor
      @changeable_orders = []
      @currency_symbol = currencyConfig.symbol

      for distributor in @orders_by_distributor
        @findChangeableOrders(distributor.distributed_orders)
        @updateRunningBalance(distributor.distributed_orders)


    updateRunningBalance: (orders) ->
      for order, i in orders
        balances = orders.slice(i,orders.length).map (o) -> parseFloat(o.outstanding_balance)
        running_balance = balances.reduce (a,b) -> a+b
        order.running_balance = running_balance.toFixed(2)

    findChangeableOrders: (orders) ->
      for order in orders when order.changes_allowed
        @changeable_orders.push(order)
