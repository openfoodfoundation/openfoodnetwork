Darkswarm.controller "DistributorNodeCtrl", ($scope, HashNavigation, $anchorScroll) ->
  $scope.toggle = ->
    HashNavigation.toggle $scope.distributor.hash

  $scope.open = ->
    HashNavigation.active($scope.distributor.hash)

  if $scope.open()
    $anchorScroll()
