angular.module("admin.enterprises")
  .controller "enterpriseCtrl", ($scope, Enterprise, PaymentMethods, ShippingMethods) ->
    $scope.Enterprise = Enterprise.enterprise
    $scope.PaymentMethods = PaymentMethods.paymentMethods
    $scope.ShippingMethods = ShippingMethods.shippingMethods

    for PaymentMethod in $scope.PaymentMethods
      PaymentMethod.selected = if PaymentMethod.id in $scope.Enterprise.payment_method_ids then true else false

    $scope.paymentMethodsColor = ->
      if $scope.PaymentMethods.length > 0
        if $scope.selectedPaymentMethodsCount() > 0 then "blue" else "red"
      else
        "red"

    $scope.selectedPaymentMethodsCount = ->
      $scope.PaymentMethods.reduce (count, PaymentMethod) ->
        count++ if PaymentMethod.selected
        count
      , 0

    for ShippingMethod in $scope.ShippingMethods
      ShippingMethod.selected = if ShippingMethod.id in $scope.Enterprise.shipping_method_ids then true else false

    $scope.shippingMethodsColor = ->
      if $scope.ShippingMethods.length > 0
        if $scope.selectedShippingMethodsCount() > 0 then "blue" else "red"
      else
        "red"

    $scope.selectedShippingMethodsCount = ->
      $scope.ShippingMethods.reduce (count, ShippingMethod) ->
        count++ if ShippingMethod.selected
        count
      , 0