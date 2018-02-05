angular.module("admin.subscriptions").controller "SubscriptionsController", ($scope, Subscriptions, Columns, RequestMonitor, shops, ShippingMethods, PaymentMethods) ->
  $scope.columns = Columns.columns
  $scope.shops = shops
  $scope.shop_id = if shops.length == 1 then shops[0].id else null
  $scope.shippingMethodsByID = ShippingMethods.byID
  $scope.paymentMethodsByID = PaymentMethods.byID
  $scope.RequestMonitor = RequestMonitor
  $scope.query = ''

  $scope.$watch "shop_id", ->
    if $scope.shop_id?
      $scope.subscriptions = Subscriptions.index("q[shop_id_eq]": $scope.shop_id, "q[canceled_at_null]": true)

  $scope.itemCount = (subscription) ->
    subscription.subscription_line_items.reduce (sum, sli) ->
      return sum + sli.quantity
    , 0

  $scope.filtersApplied = ->
    $scope.query != ''
