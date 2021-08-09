angular.module('Darkswarm').factory 'Orders', (orders, shops, currencyConfig)->
  new class Orders
    all: orders
    changeable: []
    shops: shops
    shopsByID: {}
    currencySymbol = currencyConfig.symbol

    constructor: ->
      for shop in @shops
        shop.orders = []
        shop.balance = 0.0
        @shopsByID[shop.id] = shop

      for order in @all by -1
        shop = @shopsByID[order.shop_id]
        shop.orders.unshift order

        @changeable.unshift(order) if order.changes_allowed

        @updateRunningBalance(shop, order)

    updateRunningBalance: (shop, order) ->
      shop.balance += parseFloat(order.outstanding_balance)
      order.runningBalance = shop.balance.toFixed(2)
