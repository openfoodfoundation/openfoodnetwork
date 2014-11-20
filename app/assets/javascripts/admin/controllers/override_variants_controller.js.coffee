angular.module("ofn.admin").controller "AdminOverrideVariantsCtrl", ($scope, Indexer, hubs, producers, products) ->
  $scope.hubs = hubs
  $scope.hub = null
  $scope.products = products
  $scope.producers = Indexer.index producers

  $scope.selectHub = ->
    $scope.hub = (hub for hub in hubs when hub.id == $scope.hub_id)[0]