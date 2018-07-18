angular.module("Darkswarm").controller "AuthorisedShopsCtrl", ($scope, Customers, Shops) ->
  $scope.customers = Customers.index()
  $scope.shopsByID = Shops.byID
