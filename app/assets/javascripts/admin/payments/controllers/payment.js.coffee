angular.module("admin.payments").controller "PaymentCtrl", ($scope, $timeout, Payment, PaymentMethods, Loading) ->
  $scope.form_data = Payment.form_data
  $scope.submitted = false

  $scope.submitPayment = () ->
    return false if $scope.submitted == true
    $scope.submitted = true
    Loading.message = t("submitting_payment")
    Payment.purchase()

    # If stripe, get token then submitPayment


    # Otherwise just submit

    # Default form action is sth like: /admin/orders/R257708112/payments
