angular.module("admin.standingOrders").controller "StandingOrdersController", ($scope, StandingOrders, Columns, shops, ShippingMethods, PaymentMethods) ->
  $scope.columns = Columns.columns
  $scope.shops = shops
  $scope.shop_id = if shops.length == 1 then shops[0].id else null
  $scope.shippingMethodsByID = ShippingMethods.byID
  $scope.paymentMethodsByID = PaymentMethods.byID
  $scope.standingOrders = StandingOrders.all

  $scope.$watch "shop_id", ->
    if $scope.shop_id?
      StandingOrders.index("q[shop_id_eq]": $scope.shop_id, "q[canceled_at_null]": true)

  $scope.itemCount = (standingOrder) ->
    standingOrder.standing_line_items.reduce (sum, sli) ->
      return sum + sli.quantity
    , 0
