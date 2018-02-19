angular.module("admin.subscriptions").controller "SubscriptionController", ($scope, Subscription, SubscriptionForm, Customers, Schedules, PaymentMethods, ShippingMethods) ->
  $scope.subscription = new Subscription()
  $scope.errors = null
  $scope.save = null
  $scope.customers = Customers.all
  $scope.schedules = Schedules.all
  $scope.paymentMethods = PaymentMethods.all
  $scope.shippingMethods = ShippingMethods.all
  $scope.distributor_id = $scope.subscription.shop_id # variant selector requires distributor_id
  $scope.view = if $scope.subscription.id? then 'review' else 'details'
  $scope.nextCallbacks = {}
  $scope.backCallbacks = {}
  $scope.creditCards = []
  $scope.setView = (view) -> $scope.view = view
  $scope.stepTitleFor = (step) -> t("admin.subscriptions.steps.#{step}")
  $scope.registerNextCallback = (view, callback) => $scope.nextCallbacks[view] = callback
  $scope.registerBackCallback = (view, callback) => $scope.backCallbacks[view] = callback
  $scope.next = -> $scope.nextCallbacks[$scope.view]()
  $scope.back = -> $scope.backCallbacks[$scope.view]()

  $scope.shipAddressFromBilling = =>
    angular.extend($scope.subscription.ship_address, $scope.subscription.bill_address)

  $scope.$watch 'subscription_form', ->
    form = new SubscriptionForm($scope.subscription_form, $scope.subscription)
    $scope.errors = form.errors
    $scope.save = form.save
