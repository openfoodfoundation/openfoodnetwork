angular.module("admin.standingOrders").controller "StandingOrderController", ($scope, $http, $window, StandingOrder, customers, schedules, paymentMethods, shippingMethods) ->
  $scope.standingOrder = new StandingOrder()
  $scope.customers = customers
  $scope.schedules = schedules
  $scope.paymentMethods = paymentMethods
  $scope.shippingMethods = shippingMethods
  $scope.errors = $scope.standingOrder.errors
  $scope.distributor_id = $scope.standingOrder.shop_id # variant selector requires distributor_id
  $scope.view = if $scope.standingOrder.id? then 'review' else 'details'
  $scope.nextCallbacks = {}
  $scope.backCallbacks = {}

  $scope.save = ->
    $scope.standing_order_form.$setPristine()
    if $scope.standingOrder.id?
      $scope.standingOrder.update().then (response) ->
        $window.location.href = "/admin/standing_orders"
    else
      $scope.standingOrder.create().then (response) ->
        $window.location.href = "/admin/standing_orders"

  $scope.setView = (view) -> $scope.view = view

  $scope.stepTitleFor = (step) -> t("admin.standing_orders.steps.#{step}")

  $scope.registerNextCallback = (view, callback) => $scope.nextCallbacks[view] = callback
  $scope.registerBackCallback = (view, callback) => $scope.backCallbacks[view] = callback
  $scope.next = -> $scope.nextCallbacks[$scope.view]()
  $scope.back = -> $scope.backCallbacks[$scope.view]()

  $scope.$watch "standingOrder.customer_id", (newValue, oldValue) ->
    return if !newValue? || newValue == oldValue
    $http.get("/admin/search/customer_addresses", params: { customer_id: newValue })
    .success (response) =>
      delete response.bill_address.id
      delete response.ship_address.id
      angular.extend($scope.standingOrder.bill_address, response.bill_address)
      angular.extend($scope.standingOrder.ship_address, response.ship_address)

  $scope.shipAddressFromBilling = =>
    angular.extend($scope.standingOrder.ship_address, $scope.standingOrder.bill_address)
