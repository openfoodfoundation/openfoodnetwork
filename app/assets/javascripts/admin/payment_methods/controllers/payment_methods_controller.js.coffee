angular.module("admin.paymentMethods").controller "paymentMethodsCtrl", ($scope, PaymentMethods) ->
  $scope.findPaymentMethodByID = (id) ->
    $scope.PaymentMethod = PaymentMethods.byID[id]
