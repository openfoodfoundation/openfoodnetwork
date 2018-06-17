angular.module("admin.payments").controller "PaymentCtrl", ($scope, Payment, StatusMessage) ->
  $scope.form_data = Payment.form_data
  $scope.submitted = false
  $scope.StatusMessage = StatusMessage

  $scope.submitPayment = () ->
    return false if $scope.submitted == true
    $scope.submitted = true
    StatusMessage.display 'progress', t("submitting_payment")
    Payment.purchase()
