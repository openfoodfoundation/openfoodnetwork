angular.module("admin.standingOrders").controller "StandingOrderController", ($scope, StandingOrder, customers, schedules, paymentMethods, shippingMethods) ->
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
      $scope.standingOrder.update()
    else
      $scope.standingOrder.create()

  $scope.setView = (view) -> $scope.view = view

  $scope.stepTitleFor = (step) -> t("admin.standing_orders.steps.#{step}")

  $scope.registerNextCallback = (view, callback) => $scope.nextCallbacks[view] = callback
  $scope.registerBackCallback = (view, callback) => $scope.backCallbacks[view] = callback
  $scope.next = -> $scope.nextCallbacks[$scope.view]()
  $scope.back = -> $scope.backCallbacks[$scope.view]()
