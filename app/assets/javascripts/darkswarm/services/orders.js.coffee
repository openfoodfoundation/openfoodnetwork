Darkswarm.factory 'Orders', (orders_by_distributor, currencyConfig, CurrentHub, Taxons, Dereferencer, visibleFilter, Matcher, Geo, $rootScope)->
  new class Orders
    constructor: ->
      # Populate Orders.orders from json in page.
      @orders_by_distributor = orders_by_distributor
      @currency_symbol = currencyConfig.symbol

      for distributor in @orders_by_distributor
        console.log distributor
        for order, i in distributor.distributed_orders
          balances = distributor.distributed_orders.slice(i,distributor.distributed_orders.length).map (o) -> parseFloat(o.outstanding_balance)
          running_balance = balances.reduce (a,b) -> a+b
          order.running_balance = running_balance.toFixed(2)
          console.log order
