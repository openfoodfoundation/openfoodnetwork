angular.module("ofn.admin").controller "ProvidersCtrl", ($scope, paymentMethod) ->
  if paymentMethod.type
    $scope.include_html = "/admin/payment_methods/show_provider_preferences?" +
      "provider_type=#{paymentMethod.type};" +
      "pm_id=#{paymentMethod.id};"
  else
    $scope.include_html = ""