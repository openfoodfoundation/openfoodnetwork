Darkswarm.controller "DistributorNodeCtrl", ($scope, HashNavigation, $anchorScroll) ->
  $scope.toggle = ->
    HashNavigation.toggle $scope.distributor.id

  $scope.open = ->
    HashNavigation.active($scope.distributor.id)

  if $scope.open()
    $anchorScroll()
