angular.module("admin.paymentMethods").controller "StripeController", ($scope, shops) ->
  $scope.shops = shops
