angular.module("admin.payment_methods")
  .controller "paymentMethodCtrl", ($scope, PaymentMethods) ->
    $scope.findPaymentMethodByID = (id) ->
      $scope.PaymentMethod = PaymentMethods.findByID(id)