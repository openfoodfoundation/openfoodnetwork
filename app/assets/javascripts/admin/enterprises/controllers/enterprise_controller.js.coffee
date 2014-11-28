angular.module("admin.enterprises")
  .controller "enterpriseCtrl", ($scope, longDescription, NavigationCheck, Enterprise, PaymentMethods, ShippingMethods, SideMenu) ->
    $scope.Enterprise = Enterprise.enterprise
    $scope.PaymentMethods = PaymentMethods.paymentMethods
    $scope.ShippingMethods = ShippingMethods.shippingMethods
    $scope.navClear = NavigationCheck.clear
    # htmlVariable is used by textAngular wysiwyg for the long descrtiption.
    $scope.htmlVariable = longDescription
    $scope.pristineEmail = $scope.Enterprise.email
    $scope.menu = SideMenu

    # Provide a callback for generating warning messages displayed before leaving the page. This is passed in
    # from a directive "nav-check" in the page - if we pass it here it will be called in the test suite,
    # and on all new uses of this contoller, and we might not want that .
    $scope.enterpriseNavCallback = ->
      if $scope.enterprise.$dirty
        "Your changes to the enterprise are not saved yet."

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
