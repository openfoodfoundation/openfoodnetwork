angular.module("admin.enterprises")
  .controller "enterpriseCtrl", ($scope, longDescription, Enterprise, PaymentMethods, ShippingMethods, NavigationCheck) ->
    $scope.Enterprise = Enterprise.enterprise
    $scope.PaymentMethods = PaymentMethods.paymentMethods
    $scope.ShippingMethods = ShippingMethods.shippingMethods
    # htmlVariable is used by textAngular wysiwyg for the long descrtiption.
    $scope.htmlVariable = longDescription
    # Provide a callback for a warning message displayed when leaving the page.
    navigationCallback = ->
      "You are editing an enterprise!"

    NavigationCheck.register navigationCallback

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
