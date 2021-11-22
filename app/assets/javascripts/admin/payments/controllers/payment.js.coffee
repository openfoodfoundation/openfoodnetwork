angular.module("admin.payments").controller "PaymentCtrl", ($scope, Payment, StatusMessage) ->
  $scope.form_data = Payment.form_data
  $scope.submitted = false
  $scope.StatusMessage = StatusMessage

  $scope.submitPayment = () ->
    return false if $scope.submitted
    $scope.submitted = true
    StatusMessage.display 'progress', t("spree.admin.payments.source_forms.stripe.submitting_payment")
    Payment.purchase()

  $scope.isSelected = (payment_method_id) ->
    return parseInt($scope.form_data.payment_method) == payment_method_id
