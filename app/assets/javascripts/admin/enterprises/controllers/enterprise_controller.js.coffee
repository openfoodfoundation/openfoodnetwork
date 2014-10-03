angular.module("admin.enterprises")
  .controller "enterpriseCtrl", ($scope, $rootScope, Enterprise, PaymentMethods, ShippingMethods) ->
    $scope.Enterprise = Enterprise.enterprise
    $scope.PaymentMethods = PaymentMethods.paymentMethods
    $scope.ShippingMethods = ShippingMethods.shippingMethods
    $scope.$on "$routeChangeStart", (event, newUrl, oldUrl) ->
      event.preventDefault()

    for payment_method in $scope.PaymentMethods
      payment_method.selected = payment_method.id in $scope.Enterprise.payment_method_ids

    $scope.paymentMethodsColor = ->
      if $scope.PaymentMethods.length > 0
        if $scope.selectedPaymentMethodsCount() > 0 then "blue" else "red"
      else
        "red"

    $scope.selectedPaymentMethodsCount = ->
      $scope.PaymentMethods.reduce (count, payment_method) ->
        count++ if payment_method.selected
        count
      , 0

    for shipping_method in $scope.ShippingMethods
      shipping_method.selected = shipping_method.id in $scope.Enterprise.shipping_method_ids

    $scope.shippingMethodsColor = ->
      if $scope.ShippingMethods.length > 0
        if $scope.selectedShippingMethodsCount() > 0 then "blue" else "red"
      else
        "red"

    $scope.selectedShippingMethodsCount = ->
      $scope.ShippingMethods.reduce (count, shipping_method) ->
        count++ if shipping_method.selected
        count
      , 0
