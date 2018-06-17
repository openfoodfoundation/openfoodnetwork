angular.module("admin.payments").controller "PaymentCtrl", ($scope, Payment, Loading) ->
  $scope.form_data = Payment.form_data
  $scope.submitted = false

  $scope.submitPayment = () ->
    return false if $scope.submitted == true
    $scope.submitted = true
    Loading.message = t("submitting_payment")
    Payment.purchase()
