Darkswarm.controller "DistributorNodeCtrl", ($scope, HashNavigation, $anchorScroll) ->
  $scope.toggle = ->
    HashNavigation.toggle $scope.distributor
  $scope.open = ->
    HashNavigation.active($scope.distributor)
    
  if $scope.open()
    $anchorScroll()
