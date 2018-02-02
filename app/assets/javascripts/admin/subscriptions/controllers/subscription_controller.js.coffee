angular.module("admin.standingOrders").controller "StandingOrderController", ($scope, StandingOrder, StandingOrderForm, customers, schedules, paymentMethods, shippingMethods) ->
  $scope.standingOrder = new StandingOrder()
  $scope.errors = null
  $scope.save = null
  $scope.customers = customers
  $scope.schedules = schedules
  $scope.paymentMethods = paymentMethods
  $scope.shippingMethods = shippingMethods
  $scope.distributor_id = $scope.standingOrder.shop_id # variant selector requires distributor_id
  $scope.view = if $scope.standingOrder.id? then 'review' else 'details'
  $scope.nextCallbacks = {}
  $scope.backCallbacks = {}
  $scope.creditCards = []
  $scope.setView = (view) -> $scope.view = view
  $scope.stepTitleFor = (step) -> t("admin.standing_orders.steps.#{step}")
  $scope.registerNextCallback = (view, callback) => $scope.nextCallbacks[view] = callback
  $scope.registerBackCallback = (view, callback) => $scope.backCallbacks[view] = callback
  $scope.next = -> $scope.nextCallbacks[$scope.view]()
  $scope.back = -> $scope.backCallbacks[$scope.view]()

  $scope.shipAddressFromBilling = =>
    angular.extend($scope.standingOrder.ship_address, $scope.standingOrder.bill_address)

  $scope.$watch 'standing_order_form', ->
    form = new StandingOrderForm($scope.standing_order_form, $scope.standingOrder)
    $scope.errors = form.errors
    $scope.save = form.save
