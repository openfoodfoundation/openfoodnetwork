angular.module("admin.enterprises")
  .controller "enterpriseCtrl", ($scope, Enterprise, PaymentMethods) ->
    $scope.Enterprise = Enterprise.enterprise
    $scope.PaymentMethods = PaymentMethods.paymentMethods

    for PaymentMethod in $scope.PaymentMethods
      PaymentMethod.selected = if PaymentMethod.id in $scope.Enterprise.payment_method_ids then true else false

    $scope.selectedPaymentMethodsCount = ->
      $scope.PaymentMethods.reduce (count, PaymentMethod) ->
        count++ if PaymentMethod.selected
        count
      , 0

    $scope.paymentMethodsColor = ->
      if $scope.PaymentMethods.length > 0
        if $scope.selectedPaymentMethodsCount() > 0 then "blue" else "red"
      else
        "red"