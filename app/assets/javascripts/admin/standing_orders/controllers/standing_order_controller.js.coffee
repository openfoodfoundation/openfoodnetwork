angular.module("admin.standingOrders").controller "StandingOrderController", ($scope, $http, $window, StatusMessage, StandingOrder, customers, schedules, paymentMethods, shippingMethods) ->
  $scope.standingOrder = new StandingOrder()
  $scope.customers = customers
  $scope.schedules = schedules
  $scope.paymentMethods = paymentMethods
  $scope.shippingMethods = shippingMethods
  $scope.errors = {}
  $scope.distributor_id = $scope.standingOrder.shop_id # variant selector requires distributor_id
  $scope.view = if $scope.standingOrder.id? then 'review' else 'details'
  $scope.nextCallbacks = {}
  $scope.backCallbacks = {}

  successCallback = (response) ->
    StatusMessage.display 'success', 'Saved. Redirecting...'
    $window.location.href = "/admin/standing_orders"

  errorCallback = (response) ->
    if response.data?.errors?
      angular.extend($scope.errors, response.data.errors)
      keys = Object.keys(response.data.errors)
      StatusMessage.display 'failure', response.data.errors[keys[0]][0]
    else
      # Happens when there are sync issues between SO and initialised orders
      # We save the SO, but open a dialog, so want to stay on the page
      StatusMessage.display 'success', 'Saved'

  formInvalid = -> StatusMessage.display 'failure', t('admin.standing_orders.details.invalid_error')

  $scope.save = ->
    return formInvalid() unless $scope.standing_order_form.$valid
    delete $scope.errors[k] for k, v of $scope.errors
    $scope.standing_order_form.$setPristine()
    StatusMessage.display 'progress', 'Saving...'
    if $scope.standingOrder.id?
      $scope.standingOrder.update().then successCallback, errorCallback
    else
      $scope.standingOrder.create().then successCallback, errorCallback

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

  $scope.shipAddressFromBilling = =>
    angular.extend($scope.standingOrder.ship_address, $scope.standingOrder.bill_address)
