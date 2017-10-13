angular.module("admin.paymentMethods").controller "StripeController", ($scope, $http, shops) ->
  $scope.shops = shops
  $scope.stripe_account = {}

  $scope.$watch "paymentMethod.preferred_enterprise_id", (newID, oldID) ->
    return unless newID?
    $scope.stripe_account = {}
    $http.get("/admin/stripe_accounts/status.json?enterprise_id=#{newID}").success (data) ->
      angular.extend($scope.stripe_account, data)
    .error (response) ->
      $scope.stripe_account.status = "request_failed"

  $scope.current_enterprise_stripe_path = ->
    return unless $scope.paymentMethod.preferred_enterprise_id?
    permalink = shops.filter((shop) ->
      shop.id == $scope.paymentMethod.preferred_enterprise_id
    )[0].permalink
    "/admin/enterprises/#{permalink}/edit#/payment_methods"
