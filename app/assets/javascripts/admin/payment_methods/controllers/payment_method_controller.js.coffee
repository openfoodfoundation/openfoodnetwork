angular.module("admin.paymentMethods")
  .controller "paymentMethodCtrl", ($scope, PaymentMethods) ->
    $scope.findPaymentMethodByID = (id) ->
      $scope.PaymentMethod = PaymentMethods.findByID(id)
