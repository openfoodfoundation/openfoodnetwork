angular.module("admin.standingOrders").controller "StandingOrderController", ($scope, $http, StandingOrder, StandingOrderForm, customers, schedules, paymentMethods, shippingMethods) ->
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

  $scope.$watch "standingOrder.customer_id", (newValue, oldValue) ->
    return if !newValue? || newValue == oldValue
    $http.get("/admin/customers/#{newValue}/addresses")
    .success (response) =>
      delete response.bill_address.id
      delete response.ship_address.id
      angular.extend($scope.standingOrder.bill_address, response.bill_address)
      angular.extend($scope.standingOrder.ship_address, response.ship_address)
      $scope.shipAddressFromBilling() unless response.ship_address.address1?
    $http.get("/admin/customers/#{newValue}/cards")
    .success (response) => $scope.creditCards = response.cards

  $scope.shipAddressFromBilling = =>
    angular.extend($scope.standingOrder.ship_address, $scope.standingOrder.bill_address)

  $scope.$watch 'standing_order_form', ->
    form = new StandingOrderForm($scope.standing_order_form, $scope.standingOrder)
    $scope.errors = form.errors
    $scope.save = form.save
